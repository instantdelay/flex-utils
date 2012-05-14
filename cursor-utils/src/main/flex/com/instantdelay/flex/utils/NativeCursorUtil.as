/*
Copyright (c) 2012 Spencer Van Hoose

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package com.instantdelay.flex.utils
{
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.events.Event;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.net.registerClassAlias;
   import flash.ui.MouseCursorData;
   import flash.utils.ByteArray;

   /**
    * Utility class containing functions to ease use of native cursors in FLEX
    * and AIR applications.
    * 
    * @author Spencer Van Hoose
    * 
    */
   public class NativeCursorUtil {
      
      {
         registerClassAlias("__pt", Point);
      }
      
      public function NativeCursorUtil() {
         throw "Static utility class";
      }
      
      /**
       * Read a MouseCursorData object from the byte array. Uses the same custom
       * serialization format as writeFlexCursor. Ideal for pre-rendering a native
       * cursor and embedding it in applications.
       * 
       * @param b ByteArray with the cursor data starting at the current position.
       * @return The deserialized MouseCursorData.
       * 
       */
      public static function readFlexCursor(b:ByteArray):MouseCursorData {
         var len:int = b.readInt();
         
         if (len !== b.length) {
            throw "Length mismatch";
         }
         
         var hotspot:Point = b.readObject();
         var fps:Number = b.readFloat();
         var width:int = b.readInt();
         var height:int = b.readInt();
         var transparent:Boolean = b.readBoolean();
         
         var frameCount:int = b.readInt();
         var data:Vector.<BitmapData> = new Vector.<BitmapData>(frameCount);
         for (var i:int = 0; i < frameCount; i++) {
            var frame:BitmapData = new BitmapData(width, height, transparent, 0x00FFFFFF);
            frame.setPixels(frame.rect, b);
            data[i] = frame;
         }
         
         var cursor:MouseCursorData = new MouseCursorData();
         cursor.data = data;
         cursor.frameRate = fps;
         cursor.hotSpot = hotspot;
         return cursor;
      }
      
      /**
       * Write a MouseCursorData object to a ByteArray. Uses the same custom
       * serialization format as readFlexCursor. Ideal for pre-rendering a native
       * cursor and embedding it in applications.
       * 
       * @param b MouseCursorData object to serialize.
       * @return A ByteArray containing the data.
       * 
       */
      public static function writeFlexCursor(m:MouseCursorData):ByteArray {
         var data:Vector.<BitmapData> = m.data;
         var d0:BitmapData = data[0];
         
         var bytes:ByteArray = new ByteArray();
         bytes.writeInt(0);
         bytes.writeObject(m.hotSpot);
         bytes.writeFloat(m.frameRate);
         
         bytes.writeInt(d0.width);
         bytes.writeInt(d0.height);
         bytes.writeBoolean(d0.transparent);
         
         bytes.writeInt(data.length);
         for (var i:int = 0; i < data.length; i++) {
            bytes.writeBytes(data[i].getPixels(data[i].rect));
         }
         
         bytes.position = 0;
         bytes.writeInt(bytes.length);
         return bytes;
      }
      
      /**
       * Renders frameCount frames of the given DisplayObject into a BitmapData vector.
       * Drives animation by dispatching an ENTER_FRAME event between captures.
       * 
       * <p>Useful for converting an existing flex-based cursor to bitmap data for use
       * in a native cursor.
       * 
       * @param d DisplayObject to render
       * @param frameCount Number of frames to capture
       * @param skip Number of frames to skip between captures. Default of 1 captures each
       *         frame to a BitmapData.
       * @return Vector of frames
       * 
       */
      public static function drawFrames(d:DisplayObject, frameCount:int, skip:int=1):Vector.<BitmapData> {
         var bitData:BitmapData;
         var data:Vector.<BitmapData> = new Vector.<BitmapData>();
         
         var width:int = d.width;
         var height:int = d.height;
         
         var m:Matrix = new Matrix();
         m.translate(width / 2 - 0.5, height / 2 - 0.5);
         
         var frameEvent:Event = new Event(Event.ENTER_FRAME);
         d.dispatchEvent(new Event(Event.ADDED));
         
         for (var i:int = 0; i < frameCount; ) {
            bitData = new BitmapData(width, height, true, 0x00000000);
            bitData.draw(d, m);
            data[data.length] = bitData;
            
            for (var k:int = 0; k < skip; k++) {
               d.dispatchEvent(frameEvent);
            }
            i += k;
         }
         
         return data;
      }
      
      /**
       * Renders frameCount frames of the given ICursorRenderer into a BitmatpData
       * vector. Drives animation by calling nextFrame() on the renderer between
       * each capture.
       * 
       * <p>Useful for designing a cursor in flex/actionscript and rendering the
       * result to bitmap data for use in a native cursor.
       * 
       * @param anim The ICursorRenderer to render
       * @param frameCount Number of frames to capture
       * @return Vector of frames
       * 
       */
      public static function drawRendererFrames(anim:ICursorRenderer, frameCount:int):Vector.<BitmapData> {
         var bitData:BitmapData;
         var data:Vector.<BitmapData> = new Vector.<BitmapData>();
         
         var width:int = anim.width;
         var height:int = anim.height;
         
         var m:Matrix = new Matrix();
         m.translate(width / 2 - 0.5, height / 2 - 0.5);
         
         for (var i:int = 0; i < frameCount; i++) {
            bitData = new BitmapData(width, height, true, 0x00000000);
            bitData.draw(anim, m);
            data[data.length] = bitData;
            anim.nextFrame();
         }
         
         return data;
      }
      
      /**
       * Create a MouseCursorData object by drawing the given renderer.
       *  
       * @param anim The ICursorRenderer to draw.
       * @param frameCount Number of frames to capture
       * @param frameRate FPS at which to display the resulting cursor.
       * @param hotspot Offset of the cursor hotspot from the top-left. Defaults to (0, 0)
       * @return A MouseCursorData object
       * 
       */
      public static function createCursorData(anim:ICursorRenderer, frameCount:int,
                                              frameRate:Number, hotspot:Point=null):MouseCursorData {
         var m:MouseCursorData = new MouseCursorData();
         m.data = drawRendererFrames(anim, frameCount);
         m.frameRate = frameRate;
         if (hotspot != null) {
            m.hotSpot = hotspot;
         }
         return m;
      }
      
   }
}