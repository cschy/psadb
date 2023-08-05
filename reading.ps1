Param (
    [switch]$d = $false
)
. .\utils.ps1
$ErrorActionPreference = "Stop";
if ($d){
    $DebugPreference = "Continue";
}


function gettask([int]$seconds=7) {
    adb.exe shell am start -n com.tencent.mm/com.tencent.mm.plugin.webview.ui.tools.WebViewUI -a android.intent.action.VIEW -d http://zl1223203438-1314804847.cos.ap-nanjing.myqcloud.com/index.html;
    Start-Sleep -Seconds $seconds;
}

function readbook([int]$seconds=3) {
    scroll ($screen.width / 2) ($screen.width / 2) $screen.height 0;
    scroll ($screen.width / 2) ($screen.width / 2) $screen.height 0;
    Start-Sleep -Seconds $seconds;
    back 3000;
}

function flush($info) {
    click $info 300;
    click $(Traits $(get_page) {Param($i) $i.text -eq "刷新"}) 300;
}


try {
    adb.exe root;
    Write-Debug "Physical size<$($screen.width)x$($screen.height)>";
    Write-Debug "exec_or_shell: $exec_or_shell";
    # adb.exe shell am start com.tencent.mm/com.tencent.mm.ui.LauncherUI;

    while($true) {
        gettask;
        $homepage = get_page;
        $closebutton = @(Traits $homepage {Param($i) $i.class -eq "android.widget.ImageView"})[-2];
        $moreinfo = @(Traits $homepage {Param($i) $i.class -eq "android.widget.ImageView"})[-1];
        # flush $moreinfo;

        $state_wait = Traits $homepage {Param($i) $i.text -eq "复制推广文案发给好友"};
        $copylink = Traits $homepage {Param($i) $i.text -eq "复制"};

        if (!$state_wait -and !$copylink){
            break;
        }
        
        if ($state_wait){
            click $state_wait 500;
            click $(Traits $(get_page) {Param($i) $i.text -eq "确定"}) 500;
            click $(Traits $(get_page) {Param($i) $i.text -eq "确定"});
            back;
            #为了dump出正确的view，刷新
            flush $moreinfo;

            $waitnode = Traits $(get_page) {Param($i) $i.text.Contains("分钟")};
            click $closebutton;
            [int]$waittime = ($waitnode.text | sed 's/[^0-9]//g');
            Write-Debug "等待$($waittime)分钟";
            Start-Sleep -Seconds (60*($waittime)+5);
            gettask;
            $copylink = Traits $(get_page) {Param($i) $i.text -eq "复制"};
        }

        click $copylink 500;
        click $(Traits $(get_page) {Param($i) $i.text -eq "确定"});
        click $closebutton;
        [string]$url = @([string]$(adb.exe shell am broadcast -a clipper.get) -split "(data=)")[-1];
        $url.Trim("`"");
        adb.exe shell am start -n com.tencent.mm/com.tencent.mm.plugin.webview.ui.tools.WebViewUI -a android.intent.action.VIEW -d $url;
        Start-Sleep -Seconds 7;
        $readcount = 0;
        while($readcount -lt 30) {
            readbook;
            $readcount = $readcount + 1;
        }
        Start-Sleep -Seconds 3;
    }
}
catch {
    $reason = "$(Get-Date) $($PSItem.Exception.Message)";
    $stack_trace = "$($PSItem.InvocationInfo.PositionMessage)`n$($PSItem.ScriptStackTrace)";
    $detail = "$reason`n$stack_trace`n";
    Write-Output $detail >> reading.log;
    
    Write-Error $detail;
}
