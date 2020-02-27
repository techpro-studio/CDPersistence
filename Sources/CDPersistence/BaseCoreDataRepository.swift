//
//  File.swift
//  
//
//  Created by Alex on 20.02.2020.
//

import Foundation
import CoreData
import AbstractPersistence

open class BaseCoreDataRepository<T:CDRepresentable>: AbstractRepository where T.CoreDataType.DomainType == T{

    public let managedObjectContextFactory: ManagedObjectContextFactory

    public lazy var managedObjectContext = self.managedObjectContextFactory.make()

    public init(managedObjectContextFactory: ManagedObjectContextFactory) {
        self.managedObjectContextFactory = managedObjectContextFactory
    }

    public func save(value: T) {
        let managedObject = self.getManagedObjects(predicate: self.getIdPredicate(id: value.id)).first ?? create()
        value.update(value: managedObject)
        try? self.managedObjectContext.save()
    }

    private func create() -> T.CoreDataType {
        return NSEntityDescription.insertNewObject(forEntityName: T.CoreDataType.entityName, into: self.managedObjectContext) as! T.CoreDataType
    }

    public func remove(value: T) {
        self.remove(id: value.id)
    }

    public func getById(id: T.Identifier) -> T? {
        return self.get(predicate: self.getIdPredicate(id: id))
    }

    private func getIdPredicate(id: T.Identifier) -> NSPredicate {
        return NSPredicate(format: "\(T.CoreDataType.primaryKey)=\(id)")
    }

    public func remove(id: T.Identifier) {
        guard let object = self.getManagedObjects(predicate: getIdPredicate(id: id)).first as? NSManagedObject  else {
            return
        }
        self.managedObjectContext.delete(object)
    }

    public func find(predicate: NSPredicate) -> [T] {
        return self.getManagedObjects(predicate: predicate).map { $0.asDomain() }
    }

    private func getManagedObjects(predicate: NSPredicate) -> [T.CoreDataType] {
        let request = NSFetchRequest<T.CoreDataType>(entityName: T.CoreDataType.entityName)
        request.predicate = predicate
        return (try? self.managedObjectContext.fetch(request)) ?? []
    }

    public func get(predicate: NSPredicate) -> T? {
        return self.getManagedObjects(predicate: predicate).first?.asDomain()
    }
}
