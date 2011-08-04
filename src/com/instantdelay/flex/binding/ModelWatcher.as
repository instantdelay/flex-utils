package com.instantdelay.flex.binding
{
   import flash.events.Event;
   import flash.events.IEventDispatcher;
   
   import mx.binding.BindabilityInfo;
   import mx.binding.utils.ChangeWatcher;
   import mx.collections.IList;
   import mx.events.CollectionEvent;
   import mx.events.CollectionEventKind;
   import mx.utils.DescribeTypeCache;

   /**
    * 
    * @author Spencer Van Hoose
    * 
    */
   public class ModelWatcher {
      
      private var _host:IEventDispatcher = null;
      private var _property:String;
      private var _events:Object = null;
      private var _handler:Function = null;
      private var _children:Array = [];
      private var _value:IEventDispatcher;
      
      public function ModelWatcher(property:String, handler:Function=null) {
         _property = property;
         _handler = handler;
      }
      
      public static function watch(host:IEventDispatcher, property:String, handler:Function=null):ModelWatcher {
         var watcher:ModelWatcher = new ModelWatcher(property, handler);
         watcher.updateParent(host);
         return watcher;
      }
      
      public function createChild(property:String, handler:Function=null):ModelWatcher {
         var watcher:ModelWatcher = new ModelWatcher(property, handler);
         _children.push(watcher);
         watcher.updateParent(_host === null ? null : IEventDispatcher(_host[_property]));
         return watcher;
      }
      
      public function updateParent(parent:IEventDispatcher):void {
         var eventType:String;
         
         if (_host !== null) {
            for (eventType in _events) {
               _host.removeEventListener(eventType, directChangeHandler);
            }
         }
         
         _host = parent;
         
         if (_host !== null) {
            
            if (!_events) {
               var info:BindabilityInfo =
                  DescribeTypeCache.describeType(_host).bindabilityInfo;
               
               _events = info.getChangeEvents(_property);
            }
            
            for (eventType in _events) {
               _host.addEventListener(eventType, directChangeHandler);
            }
         }
         
         valueChanged(_host === null ? null : IEventDispatcher(_host[_property]), false);
      }
      
      private function directChangeHandler(e:Event):void {
         valueChanged(_host[_property], true);
//         _value = _host[_property];
//         _handler(_value, true);
//         
//         updateChildren();
      }
      
      private function valueChanged(newValue:IEventDispatcher, direct:Boolean):void {
         if (_value is IList) {
            _value.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangedHandler);
         }
         
         _value = newValue;
         
         if (_value is IList) {
            _value.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangedHandler);
         }
         
         if (_handler !== null) {
            _handler(newValue, direct);
         }
         updateChildren(newValue);
      }
      
      private function updateChildren(value:IEventDispatcher):void {
         for each (var child:ModelWatcher in _children) {
            child.updateParent(value);
         }
      }
      
      private function collectionChangedHandler(e:CollectionEvent):void {
         if (e.kind == CollectionEventKind.ADD || e.kind == CollectionEventKind.REMOVE) {
            _handler(_value, true); //TODO: true?
         }
      }
   }
}