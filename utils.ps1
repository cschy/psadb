$screen_size = @(adb.exe shell wm size)[0].Substring(15);   #Physical size: 1080x2160
$screen = [PSCustomObject]@{
    width  = [int]$screen_size.Substring(0, $screen_size.IndexOf("x"))
    height = [int]$screen_size.Substring($screen_size.IndexOf("x")+1)
}

$dump_tag = "UI hierchary dumped to: /dev/tty";
#test exec-out or shell
$exec_or_shell = $null;
if ((adb.exe exec-out uiautomator dump --compressed /dev/tty) -ne $dump_tag){
    $exec_or_shell = "exec-out";
}else{
    $exec_or_shell = "shell";
}

function get_page() {
    $original = adb.exe $exec_or_shell uiautomator dump --compressed /dev/tty;
    $document = $original.Remove($original.Length - $dump_tag.Length);
    return [xml]$document;
}

function Traits($node, [scriptblock]$cond) {
    try {
        if ($cond.Invoke($node)){
            $node;
        }
    }
    catch {}
    if(!$node.HasChildNodes){
        return;
    }
    foreach ($i in $node.ChildNodes){
        Traits $i $cond;
    }
}

function get_rect([System.Xml.XmlLinkedNode]$node) {
    [string]$bounds = $node.bounds;
    [int]$bounds.Substring(1, $bounds.IndexOf(",")-1);
    [int]$bounds.Substring($bounds.LastIndexOf("[")+1, $bounds.LastIndexOf(",")-$bounds.LastIndexOf("[")-1);
    [int]$bounds.Substring($bounds.IndexOf(",")+1, $bounds.IndexOf("]")-$bounds.IndexOf(",")-1);
    [int]$bounds.Substring($bounds.LastIndexOf(",")+1, $bounds.LastIndexOf("]")-$bounds.LastIndexOf(",")-1);
}
function click([System.Xml.XmlLinkedNode]$node, [int]$ms=0) {
    if (!$node){
        #Write-Output "$(Get-Date)    $($MyInvocation.ScriptName): $($MyInvocation.ScriptLineNumber)" >> "xuexi.log";
        throw "点击节点为空";
    }
    $left, $right, $bottom, $top = get_rect $node;
    adb.exe shell input tap (($left + $right)*0.5) (($top+$bottom)*0.5);
    if ($ms -gt 0){
        Start-Sleep -Milliseconds $ms;
    }
}
function back([int]$ms=0) {
    adb.exe shell input keyevent BACK;
    if ($ms -gt 0){
        Start-Sleep -Milliseconds $ms;
    }
}
function scroll($startX, $startY, $endX, $endY) {
    adb.exe shell input swipe $startX $startY $endX $endY 500;
}

function send_text([string]$text) {
    $text = $text.Replace(" ", "\ ");
    adb.exe shell input text $text;
}