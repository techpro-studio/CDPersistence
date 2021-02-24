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

    open func save(value: T) throws {
        let managedObject = self.getManagedObjects(predicate: self.getIdPredicate(id: value.id)).first ?? create()
        value.update(value: managedObject)
        try self.managedObjectContext.save()
    }

    open func create() -> T.CoreDataType {
        return NSEntityDescription.insertNewObject(forEntityName: T.CoreDataType.entityName, into: self.managedObjectContext) as! T.CoreDataType
    }

    open func remove(value: T) throws {
        try self.remove(id: value.id)
    }

    open func insert(value: T) throws {
        let managedObject = create()
        value.update(value: managedObject)
        try? self.managedObjectContext.save()
    }

    open func insertMany(value: [T]) throws {
        try value.forEach(self.insert)
    }

    open func saveMany(value: [T]) throws {
        try value.forEach(self.save)
    }

    open func getById(id: T.Identifier) -> T? {
        return self.get(predicate: self.getIdPredicate(id: id))
    }

    open func getIdPredicate(id: T.Identifier) -> NSPredicate {
        return NSPredicate(format: "\(T.CoreDataType.primaryKey)=\(id)")
    }

    open func remove(id: T.Identifier) throws {
        guard let object = self.getManagedObjects(predicate: getIdPredicate(id: id)).first as? NSManagedObject  else {
            return
        }
        self.managedObjectContext.delete(object)
        try self.managedObjectContext.save()
    }

    open func find(request: FindRequest) -> [T] {
        return self.getManagedObjects(predicate: request.predicate, sortDescriptors: request.sortDescriptors, skip:  request.skip, limit: request.limit).map { $0.asDomain() }
    }

    open func getManagedObjects(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]?=nil, skip: Int?=nil, limit: Int?=nil) -> [T.CoreDataType] {
        let request = NSFetchRequest<T.CoreDataType>(entityName: T.CoreDataType.entityName)
        request.predicate = predicate
        request.fetchOffset = skip ?? 0
        request.fetchLimit = limit ?? 0
        request.sortDescriptors = sortDescriptors
        return (try? self.managedObjectContext.fetch(request)) ?? []
    }

    open func get(predicate: NSPredicate) -> T? {
        return self.getManagedObjects(predicate: predicate).first?.asDomain()
    }
}
