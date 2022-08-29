//
//  word.swift
//  TestApp
//
//  Created by Ethan Chan on 8/10/22.
//

import Foundation
import GRDB
import R2Shared
//fields:
/*
 locator
 nearest sentence
 */


struct Word: Codable {
    struct Id: EntityId { let rawValue: Int64 }
    let id: Id?
    /// Foreign key to the publication.
    var bookId: Book.Id
    /// Word Location in the publication.
    var locator: Locator
    // the full sentence
    var sentence: Locator
    /// Progression in the publication, extracted from the locator.
    var progression: Double?
    /// Date of creation.
    var created: Date = Date()
    init(id: Id? = nil, bookId: Book.Id, locator: Locator, sent: Locator, created: Date = Date()) {
        self.id = id
        self.bookId = bookId
        self.locator = locator
        self.sentence = sent
        self.progression = locator.locations.totalProgression
        self.created = created
    }
}

//word extends DB stuff
//TODO: add the sent
extension Word: TableRecord, FetchableRecord, PersistableRecord {
    enum Columns: String, ColumnExpression {
        case id, bookId, locator, progression, created
    }
}
//Repository for books
final class WordRepository {
    private let db: Database
    
    init(db: Database) {
        self.db = db
    }
}
    /*
    func all(for bookId: Book.Id) -> AnyPublisher<[Bookmark], Error> {
        db.observe { db in
            try Bookmark
                .filter(Bookmark.Columns.bookId == bookId)
                .order(Bookmark.Columns.progression)
                .fetchAll(db)
        }
    }
    
    func add(_ bookmark: Bookmark) -> AnyPublisher<Bookmark.Id, Error> {
        return db.write { db in
            try bookmark.insert(db)
            return Bookmark.Id(rawValue: db.lastInsertedRowID)
        }.eraseToAnyPublisher()
    }
    
    func remove(_ id: Bookmark.Id) -> AnyPublisher<Void, Error> {
        db.write { db in try Bookmark.deleteOne(db, key: id) }
    }
}

// for the default SwiftUI support
extension Word: Hashable {}
*/
