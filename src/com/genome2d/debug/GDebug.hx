package com.genome2d.debug;

import com.genome2d.debug.GDebugPriority;
import com.genome2d.debug.GDebugPriority;
import haxe.PosInfos;
import msignal.Signal.Signal1;

class GDebug {
    static private var g2d_console:String = "";
    static public var priority:Int = 0;
    static public var useNativeTrace:Bool = true;
    static public var stackTrace:Bool = true;

    static private var g2d_onDebug:Signal1<PosInfos>;
    #if swc @:extern #end
    static public var onDebug(get, never):Signal1<PosInfos>;
    #if swc @:getter(onDebug) #end
    static private function get_onDebug():Signal1<PosInfos> {
        if (g2d_onDebug == null) g2d_onDebug = new Signal1();
        return g2d_onDebug;
    }

    inline static private function g2d_internal(p_priority:Int, p_pos:PosInfos, ?p_arg1:Dynamic, ?p_arg2:Dynamic, ?p_arg3:Dynamic, ?p_arg4:Dynamic, ?p_arg5:Dynamic, ?p_arg6:Dynamic, ?p_arg7:Dynamic, ?p_arg8:Dynamic, ?p_arg9:Dynamic, ?p_arg10:Dynamic, ?p_arg11:Dynamic, ?p_arg12:Dynamic, ?p_arg13:Dynamic, ?p_arg14:Dynamic, ?p_arg15:Dynamic, ?p_arg16:Dynamic, ?p_arg17:Dynamic, ?p_arg18:Dynamic, ?p_arg19:Dynamic, ?p_arg20:Dynamic):Void {
        var args:Array<Dynamic> = new Array<Dynamic>();
        if (p_arg1 != null) args.push(p_arg1);
        if (p_arg2 != null) args.push(p_arg2);
        if (p_arg3 != null) args.push(p_arg3);
        if (p_arg4 != null) args.push(p_arg4);
        if (p_arg5 != null) args.push(p_arg5);
        if (p_arg6 != null) args.push(p_arg6);
        if (p_arg7 != null) args.push(p_arg7);
        if (p_arg8 != null) args.push(p_arg8);
        if (p_arg9 != null) args.push(p_arg9);
        if (p_arg10 != null) args.push(p_arg10);
        if (p_arg11 != null) args.push(p_arg11);
        if (p_arg12 != null) args.push(p_arg12);
        if (p_arg13 != null) args.push(p_arg13);
        if (p_arg14 != null) args.push(p_arg14);
        if (p_arg15 != null) args.push(p_arg15);
        if (p_arg16 != null) args.push(p_arg16);
        if (p_arg17 != null) args.push(p_arg17);
        if (p_arg18 != null) args.push(p_arg18);
        if (p_arg19 != null) args.push(p_arg19);
        if (p_arg20 != null) args.push(p_arg20);

        var msg:String = switch (p_priority) {
            case GDebugPriority.INFO:
                "INFO: ";
            case GDebugPriority.WARNING:
                "WARNING: ";
            case GDebugPriority.ERROR:
                "ERROR: ";
            case _:
                "DUMP: ";
        }
        if (p_pos != null) msg += p_pos.fileName+":"+p_pos.lineNumber+" : "+p_pos.methodName;
        if (args.length>0) msg += " : " + args.toString();

        g2d_console+=msg;
        if (useNativeTrace) untyped __global__["trace"](msg);
        if (g2d_onDebug != null) g2d_onDebug.dispatch(p_pos);
        if (p_priority == GDebugPriority.ERROR) throw msg;
    }

    inline static public function debug(p_priority:Int, ?p_arg1:Dynamic, ?p_arg2:Dynamic, ?p_arg3:Dynamic, ?p_arg4:Dynamic, ?p_arg5:Dynamic, ?p_arg6:Dynamic, ?p_arg7:Dynamic, ?p_arg8:Dynamic, ?p_arg9:Dynamic, ?p_arg10:Dynamic, ?p_arg11:Dynamic, ?p_arg12:Dynamic, ?p_arg13:Dynamic, ?p_arg14:Dynamic, ?p_arg15:Dynamic, ?p_arg16:Dynamic, ?p_arg17:Dynamic, ?p_arg18:Dynamic, ?p_arg19:Dynamic, ?p_arg20:Dynamic, ?pos:PosInfos):Void {
        if (priority <= p_priority) {
            g2d_internal(p_priority, pos, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8, p_arg9, p_arg10, p_arg11, p_arg12, p_arg13, p_arg14, p_arg15, p_arg16, p_arg17, p_arg18, p_arg19, p_arg20);
        }
    }

    inline static public function dump(?p_arg1:Dynamic, ?p_arg2:Dynamic, ?p_arg3:Dynamic, ?p_arg4:Dynamic, ?p_arg5:Dynamic, ?p_arg6:Dynamic, ?p_arg7:Dynamic, ?p_arg8:Dynamic, ?p_arg9:Dynamic, ?p_arg10:Dynamic, ?p_arg11:Dynamic, ?p_arg12:Dynamic, ?p_arg13:Dynamic, ?p_arg14:Dynamic, ?p_arg15:Dynamic, ?p_arg16:Dynamic, ?p_arg17:Dynamic, ?p_arg18:Dynamic, ?p_arg19:Dynamic, ?p_arg20:Dynamic, ?pos:PosInfos):Void {
        if (priority <= GDebugPriority.DUMP) {
            g2d_internal(GDebugPriority.DUMP, pos, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8, p_arg9, p_arg10, p_arg11, p_arg12, p_arg13, p_arg14, p_arg15, p_arg16, p_arg17, p_arg18, p_arg19, p_arg20);
        }
    }

    inline static public function dump_args(p_args:Array<Dynamic>, ?pos:PosInfos):Void {
        if (priority <= GDebugPriority.DUMP) {
            g2d_internal_args(GDebugPriority.DUMP, pos, p_args);
        }
    }

    inline static public function info(?p_arg1:Dynamic, ?p_arg2:Dynamic, ?p_arg3:Dynamic, ?p_arg4:Dynamic, ?p_arg5:Dynamic, ?p_arg6:Dynamic, ?p_arg7:Dynamic, ?p_arg8:Dynamic, ?p_arg9:Dynamic, ?p_arg10:Dynamic, ?p_arg11:Dynamic, ?p_arg12:Dynamic, ?p_arg13:Dynamic, ?p_arg14:Dynamic, ?p_arg15:Dynamic, ?p_arg16:Dynamic, ?p_arg17:Dynamic, ?p_arg18:Dynamic, ?p_arg19:Dynamic, ?p_arg20:Dynamic, ?pos:PosInfos):Void {
        if (priority <= GDebugPriority.INFO) {
            g2d_internal(GDebugPriority.INFO, pos, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8, p_arg9, p_arg10, p_arg11, p_arg12, p_arg13, p_arg14, p_arg15, p_arg16, p_arg17, p_arg18, p_arg19, p_arg20);
        }
    }

    inline static public function warning(?p_arg1:Dynamic, ?p_arg2:Dynamic, ?p_arg3:Dynamic, ?p_arg4:Dynamic, ?p_arg5:Dynamic, ?p_arg6:Dynamic, ?p_arg7:Dynamic, ?p_arg8:Dynamic, ?p_arg9:Dynamic, ?p_arg10:Dynamic, ?p_arg11:Dynamic, ?p_arg12:Dynamic, ?p_arg13:Dynamic, ?p_arg14:Dynamic, ?p_arg15:Dynamic, ?p_arg16:Dynamic, ?p_arg17:Dynamic, ?p_arg18:Dynamic, ?p_arg19:Dynamic, ?p_arg20:Dynamic, ?pos:PosInfos):Void {
        if (priority <= GDebugPriority.WARNING) {
            g2d_internal(GDebugPriority.WARNING, pos, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8, p_arg9, p_arg10, p_arg11, p_arg12, p_arg13, p_arg14, p_arg15, p_arg16, p_arg17, p_arg18, p_arg19, p_arg20);
        }
    }

    inline static public function error(?p_arg1:Dynamic, ?p_arg2:Dynamic, ?p_arg3:Dynamic, ?p_arg4:Dynamic, ?p_arg5:Dynamic, ?p_arg6:Dynamic, ?p_arg7:Dynamic, ?p_arg8:Dynamic, ?p_arg9:Dynamic, ?p_arg10:Dynamic, ?p_arg11:Dynamic, ?p_arg12:Dynamic, ?p_arg13:Dynamic, ?p_arg14:Dynamic, ?p_arg15:Dynamic, ?p_arg16:Dynamic, ?p_arg17:Dynamic, ?p_arg18:Dynamic, ?p_arg19:Dynamic, ?p_arg20:Dynamic, ?pos:PosInfos):Void {
        if (priority <= GDebugPriority.ERROR) {
            g2d_internal(GDebugPriority.ERROR, pos, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8, p_arg9, p_arg10, p_arg11, p_arg12, p_arg13, p_arg14, p_arg15, p_arg16, p_arg17, p_arg18, p_arg19, p_arg20);
        }
    }

    inline static private function g2d_internal_args(p_priority:Int, p_pos:PosInfos, p_args:Array<Dynamic>):Void {
        var msg:String = switch (p_priority) {
            case GDebugPriority.INFO:
                "INFO: ";
            case GDebugPriority.WARNING:
                "WARNING: ";
            case GDebugPriority.ERROR:
                "ERROR: ";
            case _:
                "DUMP: ";
        }
        if (p_pos != null) msg += p_pos.fileName+":"+p_pos.lineNumber+" : "+p_pos.methodName;
        if (p_args.length>0) msg += " : " + p_args.toString();

        g2d_console+=msg;
        if (useNativeTrace) untyped __global__["trace"](msg);
        if (g2d_onDebug != null) g2d_onDebug.dispatch(p_pos);
        if (p_priority == GDebugPriority.ERROR) throw msg;
    }
}