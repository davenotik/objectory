library objectory_base;
import 'persistent_object.dart';
import 'objectory_query_builder.dart';
import 'package:mongo_dart/bson.dart';

typedef Object FactoryMethod();

set objectory(Objectory impl) => Objectory.objectoryImpl = impl; 
Objectory get objectory => Objectory.objectoryImpl; 

abstract class Objectory{
    
  static Objectory objectoryImpl;  
  Map<String,BasePersistentObject> cache;
  Map<String,FactoryMethod> factories;    

  Objectory(){
    factories = new  Map<String,FactoryMethod>();
    cache = new Map<String,BasePersistentObject>();
  }
  
  void addToCache(PersistentObject obj) {
    cache[obj.id.toString()] = obj;
  }
  
  PersistentObject findInCache(var id) {
    if (id === null) {
      return null;
    }
    return cache[id.toString()];
  }
  PersistentObject findInCacheOrGetProxy(var id, String className) {
    if (id == null) {
      return null;
    }
    PersistentObject result = findInCache(id);
    if (result == null) {
      result = objectory.newInstance(className);
      result.id = id;
      result.notFetched = true;
    }
    return result;
  }
  BasePersistentObject newInstance(String className){
    if (factories.containsKey(className)){
      return factories[className]();
    }
    throw "Class $className have not been registered in Objectory";
  }
  PersistentObject dbRef2Object(DbRef dbRef) {
    return findInCacheOrGetProxy(dbRef.id, dbRef.collection);
  }  
  BasePersistentObject map2Object(String className, Map map){
    if (map === null) {
      map = new LinkedHashMap();
    }
    if (map.containsKey("_id")) {
      var id = map["_id"];
      if (id !== null) {
        var res = cache[id.toHexString()];
        if (res !== null) {
          print("Object from cache:  $res");
          return res;
        }
      }        
    }
    var result = newInstance(className);
    result.map = map;
    if (result is PersistentObject){
      result.id = map["_id"];    
    }
    if (result is PersistentObject) {
      if (result.id !== null) {
        objectory.addToCache(result);
      }          
    }        
    return result;
  }
  
  List<BasePersistentObject> list2listOfObjects(){}
  
  
  void registerClass(String className,FactoryMethod factory){
    factories[className] = factory;    
  }
  Future dropCollections();
  Future<bool> open(String uri);

  
  Future<PersistentObject> findOne(ObjectoryQueryBuilder selector);
  Future<List<PersistentObject>> find(ObjectoryQueryBuilder selector);
  save(PersistentObject persistentObject);
  remove(BasePersistentObject persistentObject);

  Future<Map> dropDb();
  Future<Map> wait();  
  void close();
  
}