package com.genome2d.signals;
class GCallback<TListener> {
    private var g2d_valueClasses:Array<Dynamic>;

    private var g2d_listeners:Array<TListener>;
    private var g2d_listenerCount:Int = 0;

    public function new(?p_valueClasses:Array<Dynamic>) {
        g2d_valueClasses = (p_valueClasses == null) ? [] : p_valueClasses;

        g2d_listeners = new Array<TListener>();
    }

    public function add(p_listener:TListener):Void {
        if (g2d_listeners.indexOf(p_listener) == -1) {
            g2d_listeners.push(p_listener);
            g2d_listenerCount++;
        }
    }

    public function remove(p_listener:TListener):Void {
        g2d_listeners.remove(p_listener);
    }
}

class GCallback1<TValue> extends GCallback<TValue -> Void>
{
    public function new(?p_type:Dynamic=null)
    {
        super([p_type]);
    }

    /**
		Executes the signals listeners with two arguements.
	**/
    public function dispatch(p_value:TValue):Void {
        for (i in 0...g2d_listenerCount) {
            g2d_listeners[i](p_value);
        }
    }
}

class GCallback2<TValue1,TValue2> extends GCallback<TValue1 -> TValue2 -> Void>
{
    public function new(?p_type1:Dynamic = null, ?p_type2:Dynamic = null)
    {
        super([p_type1,p_type2]);
    }

/**
		Executes the signals listeners with two arguements.
	**/
    public function dispatch(p_value1:TValue1, p_value2:TValue2):Void {
        for (i in 0...g2d_listenerCount) {
            g2d_listeners[i](p_value1, p_value2);
        }
    }
}
