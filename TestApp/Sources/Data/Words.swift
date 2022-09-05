//
//  Copyright 2021 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Combine
import Foundation
import GRDB
import R2Shared
import R2Navigator
import UIKit


struct Word: Codable {
    typealias Id = String
    
    let id: Id
    /// Foreign key to the publication.
    var bookId: Book.Id
    /// Location in the publication.
    var locator: Locator
    /// Color of the highlight.
    var color: HighlightColor
    /// Date of creation.
    var created: Date = Date()
    /// Total progression in the publication.
    var progression: Double?
    
    init(id: Id = UUID().uuidString, bookId: Book.Id, locator: Locator, color: HighlightColor, created: Date = Date()) {
        self.id = id
        self.bookId = bookId
        self.locator = locator
        //requirement : locator must have a locations.totalProgression field
        self.progression = locator.locations.totalProgression
        self.color = color
        self.created = created
    }
    init(id: Id = UUID().uuidString, bookId: Book.Id, locator: Locator, color: HighlightColor, created: Date = Date(), progression: Int) {
        self.id = id
        self.bookId = bookId
        self.locator = locator
        //requirement : locator must have a locations.totalProgression field
        self.progression = 0
        self.color = color
        self.created = created
    }
    
}

extension Word: TableRecord, FetchableRecord, PersistableRecord {
    enum Columns: String, ColumnExpression {
        case id, bookId, locator, color, created, progression
    }
}

struct WordNotFoundError: Error {}

final class WordRepository {
    private let db: Database
    
    init(db: Database) {
        self.db = db
    }
    
    func all(for bookId: Book.Id) -> AnyPublisher<[Word], Error> {
        db.observe { db in
            try Word
                .filter(Word.Columns.bookId == bookId)
                .order(Word.Columns.progression)
                .fetchAll(db)
        }
    }
    
    func highlight(for wordId: Word.Id) -> AnyPublisher<Word, Error> {
        db.observe { db in
            try Word
                .filter(Word.Columns.id == wordId)
                .fetchOne(db)
                .orThrow(WordNotFoundError())
        }
    }
    
    func add(_ word: Word) -> AnyPublisher<Word.Id, Error> {
        return db.write { db in
            try word.insert(db)
            return word.id
        }.eraseToAnyPublisher()
    }
    
    func update(_ id: Word.Id, color: HighlightColor) -> AnyPublisher<Void, Error> {
        return db.write { db in
            let filtered = Word.filter(Word.Columns.id == id)
            let assignment = Word.Columns.color.set(to: color)
            try filtered.updateAll(db, onConflict: nil, assignment)
        }.eraseToAnyPublisher()
    }
        
    func remove(_ id: Word.Id) -> AnyPublisher<Void, Error> {
        db.write { db in try Word.deleteOne(db, key: id) }
    }
}

// for the default SwiftUI support
extension Word: Hashable {}
