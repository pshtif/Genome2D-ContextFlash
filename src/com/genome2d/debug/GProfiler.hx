package com.genome2d.debug;

import haxe.PosInfos;
import flash.Lib;
import haxe.ds.StringMap;

typedef Profile = {
    var callCount:Int;
    var lastCallStart:Float;
    var lastCallElapsed:Float;
    var totalElapsed:Float;
}

class GProfiler {
    static public var showProfileCallStarts:Bool = false;
    static public var showProfileCallEnds:Bool = true;

    static private var g2d_profiles:StringMap<StringMap<Profile>> = new StringMap<StringMap<Profile>>();

    static public function startMethodProfile(?pos:PosInfos):Void {
        if (!g2d_profiles.exists(pos.className)) g2d_profiles.set(pos.className, new StringMap<Profile>());

        var profile:Profile = g2d_profiles.get(pos.className).get(pos.methodName);
        if (profile == null) {
            profile = { callCount: 0, lastCallStart: 0, lastCallElapsed: 0, totalElapsed: 0 };
            g2d_profiles.get(pos.className).set(pos.methodName, profile);
        }

        if (showProfileCallStarts) GDebug.trace("PROFILE METHOD START ["+pos.className+":"+pos.methodName+"]");

        profile.callCount++;
        #if flash
        profile.lastCallStart = Lib.getTimer();
        #end
    }

    static public function endMethodProfile(?pos:PosInfos):Void {
        #if flash
        var endTime:Float = Lib.getTimer();
        #end

        if (!g2d_profiles.exists(pos.className) || !g2d_profiles.get(pos.className).exists(pos.methodName))
            GDebug.error("PROFILE Invalid endProfile call.");

        var profile:Profile = g2d_profiles.get(pos.className).get(pos.methodName);
        profile.lastCallElapsed = endTime - profile.lastCallStart;
        profile.totalElapsed += endTime - profile.lastCallStart;

        if (showProfileCallEnds) GDebug.trace("PROFILE METHOD END ["+pos.className+":"+pos.methodName+"] [Elapsed: "+profile.lastCallElapsed+"]");
    }

    static public function showMethodProfile(p_className:String, p_methodName:String):Void {
        if (!g2d_profiles.exists(p_className) || !g2d_profiles.get(p_className).exists(p_methodName)) {
            GDebug.trace("PROFILE NO RESULT [Class: "+p_className+"] [Method: "+p_methodName+"]");
        } else {
            var profile:Profile = g2d_profiles.get(p_className).get(p_methodName);
            GDebug.trace("PROFILE RESULT [Class: "+p_className+"] [Method: "+p_methodName+"] : [Last Call Elapsed: "+ profile.lastCallElapsed+"ms] [Call count: "+ profile.callCount+"] [Total Elapsed: "+ profile.totalElapsed+"ms]");
        }
    }
}
