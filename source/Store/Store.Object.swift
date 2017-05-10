import CoreData

public typealias Object = NSManagedObject

// MARK: kvc

extension Object
{
    public func value(set value: Any?, for key: String) {
        self.setValue(value, forKey: key)
    }

    public func value<Value>(for key: String) -> Value {
        return self.value(forKey: key) as! Value
    }
}

// MARK: relationship

extension Object
{

    /*
    Returns related models using model construction method in batch derived from specified batchable protocol.
    */
    open func relationship<T:BatchableProtocol>(for name: String) -> [T] {
        let batch: Batch<T> = T.Batch(models: []) as! Batch<T>
        var models: [T] = []

        for object in self.mutableSetValue(forKey: name).allObjects as! [Object] {
            let model: T = batch.construct(with: object)
            model.id = String(id: object.objectID)
            models.append(model)
        }

        return models
    }

    /*
    Sets new relationship objects replacing all existing ones.
    */
    open func relationship(set objects: [Object], for name: String) {
        let set: NSMutableSet = self.mutableSetValue(forKey: name)
        set.removeAllObjects()
        set.addObjects(from: objects)
    }

    /*
    Sets new relationship models.
    */
    open func relationship<Model:ModelProtocol>(set models: [Model], for name: String) throws {
        guard let context: Context = self.managedObjectContext else { throw RelationshipError.noContext }
        var objects: [Object] = []

        for model in models {
            if let object: Object = try context.existingObject(with: model) {
                objects.append(object)
            } else {
                throw RelationshipError.noObject
            }
        }

        self.relationship(set: objects, for: name)
    }
}

extension Object
{
    public enum RelationshipError: Error
    {
        /*
        Managed object upon which a relationship is being updated has no context making it impossible to retrieve model
        managed objects.
        */
        case noContext

        /*
        Cannot retrieve model's managed object, it's probably not saved or got deleted. 
        */
        case noObject
    }
}

// MARK: -

extension String
{
    internal init(id: NSManagedObjectID) {
        self = id.uriRepresentation().absoluteString
    }
}