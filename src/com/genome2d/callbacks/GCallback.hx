package com.genome2d.callbacks;

class GCallback<TListener> {
    private var g2d_valueClasses:Array<Dynamic>;

    private var g2d_listenersOnce:Array<TListener>;
    private var g2d_listeners:Array<TListener>;
    private var g2d_listenerCount:Int = 0;
	
	private var g2d_iteratingDispatch:Int;
	private var g2d_iteratingDispatchCurrent:TListener;

    public function new(?p_valueClasses:Array<Dynamic>) {
        g2d_valueClasses = (p_valueClasses == null) ? [] : p_valueClasses;

        g2d_listeners = new Array<TListener>();
        g2d_listenersOnce = new Array<TListener>();
    }

    public function hasListeners():Bool {
        return g2d_listeners.length>0 || g2d_listenersOnce.length>0;
    }

    public function add(p_listener:TListener):Void {
        if (g2d_listeners.indexOf(p_listener) == -1 && g2d_listenersOnce.indexOf(p_listener) == -1) {
            g2d_listeners.push(p_listener);
            g2d_listenerCount++;
        }
    }

    public function addOnce(p_listener:TListener):Void {
        if (g2d_listeners.indexOf(p_listener) == -1 && g2d_listenersOnce.indexOf(p_listener) == -1) {
            g2d_listenersOnce.push(p_listener);
        }
    }

    public function addWithPriority(p_listener:TListener):Void {
        if (g2d_listeners.indexOf(p_listener) == -1 && g2d_listenersOnce.indexOf(p_listener) == -1) {
            g2d_listeners.unshift(p_listener);
			g2d_listenerCount++;
        }
    }

    public function remove(p_listener:TListener):Void {
		var index:Int = g2d_listeners.indexOf(p_listener);
        if (index >= 0) {
			if (index <= g2d_iteratingDispatch) g2d_iteratingDispatch--;
			g2d_listeners.remove(p_listener);
			g2d_listenerCount--;
		} else {
			g2d_listenersOnce.remove(p_listener);
		}
    }

    public function removeAll():Void {
        g2d_listeners = new Array<TListener>();
		g2d_listenerCount = 0;
		
        g2d_listenersOnce = new Array<TListener>();
    }
}

class GCallback0 extends GCallback<Void -> Void>
{
    public function new()
    {
        super([]);
    }

    public function dispatch():Void {
        g2d_iteratingDispatch = 0;		
        while (g2d_iteratingDispatch<g2d_listenerCount) {
            g2d_listeners[g2d_iteratingDispatch]();
			g2d_iteratingDispatch++;
        }

        while (g2d_listenersOnce.length>0) {
            g2d_listenersOnce.shift()();
        }
    }
}

class GCallback1<TValue> extends GCallback<TValue -> Void>
{
    public function new(?p_type:Dynamic=null) {
        super([p_type]);
    }

    public function dispatch(p_value:TValue):Void {
		g2d_iteratingDispatch = 0;		
        while (g2d_iteratingDispatch<g2d_listenerCount) {
            g2d_listeners[g2d_iteratingDispatch](p_value);
			g2d_iteratingDispatch++;
        }

        while (g2d_listenersOnce.length>0) {
            g2d_listenersOnce.shift()(p_value);
        }
    }
}

class GCallback2<TValue1,TValue2> extends GCallback<TValue1 -> TValue2 -> Void>
{
    public function new(?p_type1:Dynamic = null, ?p_type2:Dynamic = null) {
        super([p_type1,p_type2]);
    }

/**
		Executes the callbacks listeners with two arguements.
	**/
    public function dispatch(p_value1:TValue1, p_value2:TValue2):Void {
        g2d_iteratingDispatch = 0;		
        while (g2d_iteratingDispatch < g2d_listenerCount) {
            g2d_listeners[g2d_iteratingDispatch](p_value1, p_value2);
			g2d_iteratingDispatch++;
        }

        while (g2d_listenersOnce.length>0) {
            g2d_listeners.shift()(p_value1, p_value2);
        }
    }
}
