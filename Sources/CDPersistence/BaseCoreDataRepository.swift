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

    public func insert(value: T) {
        let managedObject = create()
        value.update(value: managedObject)
        try? self.managedObjectContext.save()
    }

    public func insertMany(value: [T]) {
        value.forEach(self.insert)
    }

    public func saveMany(value: [T]) {
        value.forEach(self.save)
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

    public func find(request: FindRequest) -> [T] {
        return self.getManagedObjects(predicate: request.predicate, sortDescriptors: request.sortDescriptors, skip:  request.skip, limit: request.limit).map { $0.asDomain() }
    }

    private func getManagedObjects(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]?=nil, skip: Int?=nil, limit: Int?=nil) -> [T.CoreDataType] {
        let request = NSFetchRequest<T.CoreDataType>(entityName: T.CoreDataType.entityName)
        request.predicate = predicate
        request.fetchOffset = skip ?? 0
        request.fetchLimit = limit ?? 0
        request.sortDescriptors = sortDescriptors
        return (try? self.managedObjectContext.fetch(request)) ?? []
    }

    public func get(predicate: NSPredicate) -> T? {
        return self.getManagedObjects(predicate: predicate).first?.asDomain()
    }
}
