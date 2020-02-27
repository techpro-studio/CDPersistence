import Foundation
import AbstractPersistence
import CoreData


public protocol CDRepresentable: Identifiable {
    associatedtype CoreDataType: CoreDataObject
    func update(value: CoreDataType)
}



public protocol CoreDataObject: DomainConvertibleType, NSFetchRequestResult {
    static var entityName: String { get }
    static var primaryKey: String { get }
}

