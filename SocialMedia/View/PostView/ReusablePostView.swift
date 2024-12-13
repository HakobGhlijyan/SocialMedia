//
//  ReusablePostView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/12/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import FirebaseDatabase

struct ReusablePostView: View {
    @Binding var posts: [Post]
    @State private var isFetching: Bool = true
    @State private var paginationDoc: QueryDocumentSnapshot?
    
    var basedOnUID: Bool = false
    var uid: String = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                if isFetching {
                    ProgressView()
                        .padding(.top, 30)
                } else {
                    if posts.isEmpty {
                        Text("No Post's Found")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(.top, 30)
                    } else {
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            //refresh all post
            //1: is fetch enable for progressview see
            //1.1 - Disbaling Refresh for UID based Post's
            guard !basedOnUID else { return }
            isFetching = true
            //2: all post array delete
            posts = []
            //2.1
            //Resetting Pagination Doc
            paginationDoc = nil
            //3: try again fetch
            await fetchPosts()
            print("FETCH NEW POST'S refreshable ")
            
            /*
             Since we created a new query for the UID-based posts and it contains
             compound queries, Firebase will require us to generate indexes when we run compound queries. Compound queries
             can be easily created by pasting the provided link from the console into a browser and selecting the index option.
             
             Поскольку мы создали новый запрос для записей, основанных на UID, и он содержит
             составные запросы, Firebase потребует от нас создания индексов при выполнении составных запросов. Составные запросы
             можно легко создать, вставив предоставленную ссылку из консоли в браузер и выбрав опцию индексирования.
             */
        }
        .task {
            //Fetching for one time
            guard posts.isEmpty else { return }
            await fetchPosts()
            print("FETCH NEW POST'S TASK")
        }
    }
    
    //Fetched Post
    @ViewBuilder func Posts() -> some View {
        ForEach(posts) { post in
            PostCardView(post: post) { updatedPost in
                //updating post
                //1:
                if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
                    //2: - >
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs
                }
            } onDelete: {
                //removing post
                withAnimation(.bouncy(duration: 0.25)) {
                    posts.removeAll(where: { post.id == $0.id })
                }
            }
            .onAppear {
                //Когда появится последнее сообщение, Выборка нового сообщения (Если оно есть)
                // When Last Post Appears, Fetching New Post (If There)
                if post.id == posts.last?.id && paginationDoc != nil {
                    /*
                     Зачем проверять, что разбивка документа на страницы не является нулевой?
                     Предположим, что всего имеется 40 записей, и что при первоначальной выборке было получено 20 записей,
                     при этом документ с разбивкой на страницы был 20-й записью, и что при появлении последней записи был
                     получен следующий набор из 20 записей, при этом документ с разбивкой на страницы был 40-й записью.
                     Когда он попытается получить другой набор из 20 записей, eite будет пустым, потому что больше нет
                     доступных записей, поэтому разбивка на страницы будет нулевой, и он больше не будет пытаться получить записи.
                     Why check pagination document isn't null?
                     Consider that there are 40 posts total, and that the initial fetch fetched 20 posts,
                     with the pagination document being the 20th post, and that when the last post appears,
                     it fetches the next set of 20 posts, with the pagination document being the 40th post.
                     When it tries to fetch another set of 20, eite will be empty because there are no more
                     posts available, so pagination Doc will be nil and It will no longer try to fetch the posts.
                     */
                    Task {
                        await fetchPosts()
                        print("FETCH NEW POST'S , Pagination Doc")
                    }
                }
            }
            
            Divider()
                .padding(.horizontal, 5)
                .padding(.bottom, 15)
        }
    }
    
    //Fetch Post Firebase
    //All , no UID Based
    /*
     func fetchPosts() async {
         print("FETCH POST")
         do {
             //Реализация разбивки на страницы - Implementing Pagination
             //1: - Query
             var query: Query
             if let paginationDoc {
                 query = Firestore.firestore().collection("SocialMedia_Posts")
                     .order(by: "publishedDate", descending: true)
                     .start(afterDocument: paginationDoc)
                     .limit(to: 20)
             } else {
                 query = Firestore.firestore().collection("SocialMedia_Posts")
                     .order(by: "publishedDate", descending: true)
                     .limit(to: 20)
             }
             
             //2: - Documents
             let docs = try await query.getDocuments()
             //3: - Fetch all post in compact map , deleted nil... and doc -> Post model, in: -> doc decode data for Post
             let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                 try? doc.data(as: Post.self)
             }
             //4: - Update UI
             await MainActor.run {
                 posts.append(contentsOf: fetchedPosts) // append in array
                 paginationDoc = docs.documents.last
                 //Сохранение последнего извлеченного документа, чтобы его можно было использовать для разбивки на страницы в Firebase Firestore.
                 //Saving the last extracted document so that it can be used for pagination in Firebase Firestore.
                 isFetching = false
             }
         } catch {
             print(error.localizedDescription)
         }
     }
     */
    
    //Fetch Post Firebase
    func fetchPosts() async {
        print("FETCH POST")
        do {
            //Реализация разбивки на страницы - Implementing Pagination
            //1: - Query
            var query: Query
            
            if let paginationDoc {
                query = Firestore.firestore().collection("SocialMedia_Posts")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            } else {
                query = Firestore.firestore().collection("SocialMedia_Posts")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
            }
            
            
            //- New Query For UID Based Document Fetch
            // Simply Filter the Post's Which is not belongs to this UID
            if basedOnUID {
                query = query
                    .whereField("userUID", isEqualTo: uid)
            }
            
            
            //2: - Documents
            let docs = try await query.getDocuments()
            //3: - Fetch all post in compact map , deleted nil... and doc -> Post model, in: -> doc decode data for Post
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            //4: - Update UI
            await MainActor.run {
                posts.append(contentsOf: fetchedPosts) // append in array
                paginationDoc = docs.documents.last
                //Сохранение последнего извлеченного документа, чтобы его можно было использовать для разбивки на страницы в Firebase Firestore.
                //Saving the last extracted document so that it can be used for pagination in Firebase Firestore.
                isFetching = false
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    ContentView()
}
