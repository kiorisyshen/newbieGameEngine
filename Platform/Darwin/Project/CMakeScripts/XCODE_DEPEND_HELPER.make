# DO NOT EDIT
# This makefile makes sure all linkable targets are
# up-to-date with anything they link to
default:
	echo "Do not invoke directly"

# Rules to remove targets that are older than anything to which they
# link.  This forces Xcode to relink the targets from scratch.  It
# does not seem to check these dependencies itself.
PostBuild.Common.Debug:
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/Debug/libCommon.a:
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/Debug/libCommon.a


PostBuild.Empty.Debug:
PostBuild.Common.Debug: /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/Debug/Empty
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/Debug/Empty:\
	/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/Debug/libCommon.a
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/Debug/Empty


PostBuild.NewbieGameEngineCocoa.Debug:
PostBuild.Common.Debug: /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/Debug/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/Debug/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa:\
	/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/Debug/libCommon.a
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/Debug/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa


PostBuild.Common.Release:
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/Release/libCommon.a:
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/Release/libCommon.a


PostBuild.Empty.Release:
PostBuild.Common.Release: /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/Release/Empty
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/Release/Empty:\
	/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/Release/libCommon.a
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/Release/Empty


PostBuild.NewbieGameEngineCocoa.Release:
PostBuild.Common.Release: /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/Release/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/Release/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa:\
	/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/Release/libCommon.a
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/Release/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa


PostBuild.Common.MinSizeRel:
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/MinSizeRel/libCommon.a:
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/MinSizeRel/libCommon.a


PostBuild.Empty.MinSizeRel:
PostBuild.Common.MinSizeRel: /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/MinSizeRel/Empty
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/MinSizeRel/Empty:\
	/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/MinSizeRel/libCommon.a
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/MinSizeRel/Empty


PostBuild.NewbieGameEngineCocoa.MinSizeRel:
PostBuild.Common.MinSizeRel: /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/MinSizeRel/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/MinSizeRel/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa:\
	/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/MinSizeRel/libCommon.a
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/MinSizeRel/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa


PostBuild.Common.RelWithDebInfo:
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/RelWithDebInfo/libCommon.a:
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/RelWithDebInfo/libCommon.a


PostBuild.Empty.RelWithDebInfo:
PostBuild.Common.RelWithDebInfo: /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/RelWithDebInfo/Empty
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/RelWithDebInfo/Empty:\
	/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/RelWithDebInfo/libCommon.a
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Empty/RelWithDebInfo/Empty


PostBuild.NewbieGameEngineCocoa.RelWithDebInfo:
PostBuild.Common.RelWithDebInfo: /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/RelWithDebInfo/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/RelWithDebInfo/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa:\
	/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/RelWithDebInfo/libCommon.a
	/bin/rm -f /Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Platform/Darwin/RelWithDebInfo/NewbieGameEngineCocoa.app/Contents/MacOS/NewbieGameEngineCocoa




# For each target create a dummy ruleso the target does not have to exist
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/Debug/libCommon.a:
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/MinSizeRel/libCommon.a:
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/RelWithDebInfo/libCommon.a:
/Users/shensijie/Learning/Game/newbieGameEngine/Platform/Darwin/Project/Framework/Common/Release/libCommon.a:
