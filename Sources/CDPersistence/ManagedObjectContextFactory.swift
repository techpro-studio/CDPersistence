import CoreData

public protocol ManagedObjectContextFactory {
    func make() -> NSManagedObjectContext
}

open class BaseManagedObjectContextFactory {

    fileprivate let bundle: Bundle
    fileprivate let modelName: String

    public init(bundle: Bundle, modelName: String) {
        self.bundle = bundle
        self.modelName = modelName
    }

    public func makeContext() -> NSManagedObjectContext {
        guard let url = bundle.url(forResource: modelName, withExtension: "momd"),
                            let model = NSManagedObjectModel(contentsOf: url) else {
                          fatalError()
               }
       let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
       let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
       context.persistentStoreCoordinator = storeCoordinator
       return context
    }
}

public final class SQLiteManagedObjectContextFactory:BaseManagedObjectContextFactory, ManagedObjectContextFactory {

    let sqliteStoreName: String

    public init(bundle: Bundle, modelName: String, sqliteStoreName: String) {
        self.sqliteStoreName = sqliteStoreName
        super.init(bundle: bundle, modelName: modelName)
    }

    public func make() -> NSManagedObjectContext {
        let context = super.makeContext()
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.appendingPathComponent(sqliteStoreName)
        try! context.persistentStoreCoordinator!.addPersistentStore(ofType: NSSQLiteStoreType,
                          configurationName: nil,
                          at: url!,
                          options: nil)
        return context
    }
}
