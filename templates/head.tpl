<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title><if %thread>
    <perleval 
    $TITLE=${$threads}[0]{posts}[0]{comment};
    $TITLE=~s/<(.*?)>//g;
    $TITLE=${$threads}[0]{posts}[0]{subject} ? ${$threads}[0]{posts}[0]{subject} : substr($TITLE, 0 , 20).(length($TITLE)>20 ? "..." : "");
    /><var $TITLE></else/><var %TITLE></if></title>

<meta http-equiv="Content-Type" content="text/html;charset" />
<link rel="shortcut icon" href="http://2--ch.ru/favicon.ico" />

<style type="text/css">
body { margin: 0; padding: 8px; margin-bottom: auto; }
blockquote blockquote { margin-left: 0em }
form { margin-bottom: 0px }
form .trap { display:none }
.postarea { text-align: center }
.postarea table { margin: 0px auto; text-align: left }
.thumb { border: none; float: left; margin: 2px 20px }
.nothumb { float: left; background: #eee; border: 2px dashed #aaa; text-align: center; margin: 2px 20px; padding: 1em 0.5em 1em 0.5em; }
.reply blockquote, blockquote :last-child { margin-bottom: 0em }
.reflink a { color: inherit; text-decoration: none }
.reply .filesize { margin-left: 20px }
.userdelete { float: right; text-align: center; white-space: nowrap }
.replypage .replylink { display: none }
</style>

<loop %stylesheets>
<link rel="<if !$default>alternate </if>stylesheet" type="text/css" href="/<var $filename>" title="<var $title>" />
</loop>

<script type="text/javascript">var style_cookie="ochobastyle";</script>
<script type="text/javascript">var thread_cookie = "<var %SECTION>_hidden_threads"; var lastopenfield = 0;</script>
<script type="text/javascript" src="/ochoba.js"></script>
<script type="text/javascript" src="/dklab_realplexor.js"></script>
<script src="/jquery.js" type="text/javascript" language="javascript"></script>
<script src="/jquery.MultiFile.js" type="text/javascript" language="javascript"></script>

<script type="text/javascript" src="http://2--ch.ru/cufon-yui.js"></script>
<script type="text/javascript" src="http://2--ch.ru/unown.font.js"></script>
<script type="text/javascript">
Cufon.replace("h2");
</script>
</head>
<body>




<div class="adminbar"> 
[
  <a href="http://2--ch.ru/d/" title="дискуссии о тиреч.ч">d</a>  / 
  <a href="http://2--ch.ru/b/" title="бред">b</a> ]  - 
[
  <a href="http://2--ch.ru/hb/" title="хобби">hb</a>  / 
  <a href="http://2--ch.ru/mu/" title="музыка">mu</a>  /
  <a href="http://2--ch.ru/pa/" title="живопись">pa</a>  / 
  <a href="http://2--ch.ru/wr/" title="графомания">wr</a> ]  - 
[
  <a href="http://2--ch.ru/f/" title="flash">f</a>  / 
  <a href="http://2--ch.ru/me/" title="медицина">me</a>  / 
  <a href="http://2--ch.ru/s/" title="программы">s</a>  / 
  <a href="http://2--ch.ru/tv/" title="тв и кино">tv</a>  / 
  <a href="http://2--ch.ru/wa/" title="война">wa</a>  /
  <a href="http://2--ch.ru/ve/" title="транспорт">ve</a>  /
  <a href="http://2--ch.ru/vg/" title="видеоигры">vg</a> ]  - 
[
  <a href="http://2--ch.ru/a/" title="аниме">a</a>  / 
  <a href="http://2--ch.ru/to/" title="touhou">to</a> ]  - 
[
  <a href="http://2--ch.ru/h/" title="хентай">h</a>  / 
  <a href="http://2--ch.ru/ls/" title="лоли">ls</a>  / 
  <a href="http://2--ch.ru/sex/" title="секс">sex</a> ]  -
[
  <a href="http://2--ch.ru/" title="главная">Главная</a> ]</div>
  <br>
	<if  %CONTROLLER ne "search" ><form action="/<var %SECTION>/search.fpl" method="post" style="padding:15px 10px;float:right;">
	Поиск:
	<input name="search" value="<var $search>"/>
	<input type="submit" value="Найти" />
	</form>
	</if>

<div class="logo" style="padding:15px 10px; float:left; ">
<var %TITLE></div>
	
	<hr style="clear:left;" />
	
	
	
	


