import CoreData

public typealias Object = NSManagedObject

extension Object
{
    public typealias Id = NSManagedObjectID
}

// MARK: kvc

extension Object
{
    @discardableResult public func value<Value>(set value: Value?, for key: String, transform: ((Value) -> Any?)? = nil) -> Self {
        if let value: Value = value, let transform: ((Value) -> Any?) = transform {
            self.setValue(transform(value), forKey: key)
        } else {
            self.setValue(value, forKey: key)
        }
        return self
    }

    @discardableResult public func value(set value: [String: Any?]) -> Self {
        for (key, value) in value {
            self.setValue(value, forKey: key)
        }
        return self
    }

    public func value<Value>(for key: String) -> Value? {
        return self.value(forKey: key) as! Value?
    }

    public func value<Raw, Transformed>(for key: String, transform: ((Raw) -> Transformed?)?) -> Transformed? {
        let value: Raw? = self.value(forKey: key) as! Raw?

        if let value: Raw = value, let transform: ((Raw) -> Transformed?) = transform {
            return transform(value)
        } else {
            return value as! Transformed?
        }
    }
}

// MARK: relationship

extension Object
{
    @nonobjc open func relationship(for name: String) -> [Object] {
        return self.mutableSetValue(forKey: name).allObjects as! [Object]
    }

    @nonobjc open func relationship(for name: String) -> Object? {
        return self.value(forKey: name) as! Object?
    }

    // MARK: -

    /*
    Returns related models using model construction method in batch derived from specified batchable protocol.
    */
    open func relationship<Model:BatchableProtocol>(for name: String) -> [Model] {
        let batch: Batch<Model> = Model.Batch(models: []) as! Batch<Model>
        var models: [Model] = []

        for object in self.mutableSetValue(forKey: name).allObjects as! [Object] {
            let model: Model = batch.construct(with: object)
            model.id = object.objectID
            models.append(model)
        }

        return models
    }

    open func relationship<Model:BatchableProtocol>(for name: String) -> Model? {
        if let object: Object = self.value(for: name) {
            let batch: Batch<Model> = Model.Batch(models: []) as! Batch<Model>
            let model: Model = batch.construct(with: object)
            model.id = object.objectID
            return model
        } else {
            return nil
        }
    }

    // MARK: -

    /*
    Sets new relationship objects replacing all existing ones.
    */
    @nonobjc open func relationship(set objects: [Object], for name: String) {
        let set: NSMutableSet = self.mutableSetValue(forKey: name)
        set.removeAllObjects()
        set.addObjects(from: objects)
    }

    @nonobjc open func relationship(set object: Object?, for name: String) {
        self.value(set: object, for: name)
    }

    // MARK: -

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

    open func relationship<Model:ModelProtocol>(set model: Model?, for name: String) throws {
        if let model: Model = model {
            guard let context: Context = self.managedObjectContext else { throw RelationshipError.noContext }
            if let object: Object = try context.existingObject(with: model) {
                self.relationship(set: object, for: name)
            } else {
                throw RelationshipError.noObject
            }
        } else {
            self.relationship(set: nil, for: name)
        }
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