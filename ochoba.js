function addcss(mycss) {
    var h = document.getElementsByTagName("head");
    var nSS = document.createElement("style"); 
    nSS.type = "text/css"; 
    h[0].appendChild(nSS); 
    try { 
        nSS.styleSheet.cssText=mycss;
    } catch(e) { 
        try {
            nSS.appendChild(document.createTextNode(mycss)); nSS.innerHTML=mycss; 
        } catch(e) {}
    }
}
addcss('blockquote {\nmax-height: 400px;\noverflow: auto;\n}');


var doc = document;
var postByNum = [];
var ajaxPosts = {};
var refArr = [];

function $X(path, root) {
	return doc.evaluate(path, root || doc, null, 6, null);
}
function $x(path, root) {
	return doc.evaluate(path, root || doc, null, 8, null).singleNodeValue;
}
function $del(el) {
	if(el) el.parentNode.removeChild(el);
}
function $each(list, fn) {
	if(!list) return;
	var i = list.snapshotLength;
	if(i > 0) while(i--) fn(list.snapshotItem(i), i);
}

function AJAX(b, id, fn) {
	var xhr = new XMLHttpRequest();
	xhr.onreadystatechange = function() {
		if(xhr.readyState != 4) return;
		if(xhr.status == 200) {
			var x = xhr.responseText;
			var threads = x.substring(x.search(/<form[^>]+del/) + x.match(/<form[^>]+del[^>]+>/).toString().length, x.indexOf('userdelete">') - 13).split(/<br clear="left"[\s\/>]*<h[r\s\/]*>/i);
			for(var i = 0, tLen = threads.length - 1; i < tLen; i++) {
				var tNum = threads[i].match(/<input[^>]+checkbox[^>]+>/i)[0].match(/(?:")(\d+)(?:")/)[1];
				var posts = threads[i].split(/<table[^>]*>/);
				ajaxPosts[tNum] = {keys: []};
				for(var j = 0, pLen = posts.length; j < pLen; j++) {
					var x = posts[j];
					var pNum = x.match(/<input[^>]+checkbox[^>]+>/i)[0].match(/(?:")(\d+)(?:")/)[1];
					ajaxPosts[tNum].keys.push(pNum);
					ajaxPosts[tNum][pNum] = x.substring((!/<\/td/.test(x) && /filesize">/.test(x)) ? x.indexOf('filesize">') - 13 : x.indexOf('<label'), /<\/td/.test(x) ? x.lastIndexOf('</td') : (/omittedposts">/.test(x) ? x.lastIndexOf('</span') + 7 : x.lastIndexOf('</blockquote') + 13));
					x = ajaxPosts[tNum][pNum].substr(ajaxPosts[tNum][pNum].indexOf('<blockquote>') + 12).match(/&gt;&gt;\d+/g);
					if(x) for(var r = 0; rLen = x.length, r < rLen; r++)
						getRefMap(x[r], pNum, x[r].replace(/&gt;&gt;/g, ''));
				}
			}
			fn();
		} else fn('HTTP ' + xhr.status + ' ' + xhr.statusText);
	};
	xhr.open('GET', '/' + b + '/res/' + id + '.html', true);
	xhr.send(false);
}

function delPostPreview(e) {
	var el = $x('ancestor-or-self::*[starts-with(@id,"pstprev")]', e.relatedTarget);
	if(!el) $each($X('.//div[starts-with(@id,"pstprev")]'), function(clone) {$del(clone)});
	else while(el.nextSibling) $del(el.nextSibling);
}

function showPostPreview(e) {
	var tNum = this.pathname.substring(this.pathname.lastIndexOf('/')).match(/\d+/);
    var pNum = this.hash.match(/\d+/) || tNum;
	var brd = this.pathname.match(/[^\/]+/);
	var x = e.clientX + (doc.documentElement.scrollLeft || doc.body.scrollLeft) - doc.documentElement.clientLeft + 1;
	var y = e.clientY + (doc.documentElement.scrollTop || doc.body.scrollTop) - doc.documentElement.clientTop;
	var cln = doc.createElement('div');
	cln.id = 'pstprev_' + pNum;
	cln.className = 'reply';
	cln.style.cssText = 'position:absolute; z-index:950; border:solid 1px #575763; top:' + y + 'px;' +
		(x < doc.body.clientWidth/2 ? 'left:' + x + 'px' : 'right:' + parseInt(doc.body.clientWidth - x + 1) + 'px');
	cln.addEventListener('mouseout', delPostPreview, false);
	var aj = ajaxPosts[tNum];
	var functor = function(cln, html) {
		cln.innerHTML = html;
		doRefPreview(cln);
		if(!$x('.//small', cln) && ajaxPosts[tNum] && ajaxPosts[tNum][pNum] && refArr[pNum])
			showRefMap(cln, pNum, tNum, brd);
	};
	cln.innerHTML = 'Загрузка...';
	if(postByNum[pNum]) functor(cln, postByNum[pNum].innerHTML);
	else {if(aj && aj[pNum]) functor(cln, aj[pNum]);
	else AJAX(brd, tNum, function(err) {functor(cln, err || ajaxPosts[tNum][pNum] || 'Пост не найден')})}
	$del(doc.getElementById(cln.id));
	$x('.//form[@id="delform"]').appendChild(cln);
}

function doRefPreview(node) {
	$each($X('.//a[starts-with(text(),">>")]', node || doc), function(link) {
		link.addEventListener('mouseover', showPostPreview, false);
		link.addEventListener('mouseout', delPostPreview, false);
	});
}

function getRefMap(post, pNum, rNum) {
	if(!refArr[rNum]) refArr[rNum] = pNum;
	else if(refArr[rNum].indexOf(pNum) == -1) refArr[rNum] = pNum + ', ' + refArr[rNum];
}

function showRefMap(post, pNum, tNum, brd) {
	var ref = refArr[pNum].toString().replace(/(\d+)/g, 
		'<a href="/' + brd + '/res/' + tNum + '.html#$1" onclick="highlight($1)">&gt;&gt;$1</a>');
	var map = doc.createElement('small');
	map.id = 'rfmap_' + pNum;
	map.innerHTML = '<br><i class="abbrev">&nbsp;Ответы: ' + ref + '</i><br>';
	doRefPreview(map);
	if(post) post.appendChild(map);
	else {
		var el = $x('.//a[@name="' + pNum + '"]');
		while(el.tagName != 'BLOCKQUOTE') el = el.nextSibling;
		el.parentNode.insertBefore(map, el.nextSibling);
	}
}

function doRefMap() {
	$each($X('.//a[starts-with(text(),">>")]'), function(link) {
		if(!/\//.test(link.textContent)) {
			var rNum = link.hash.match(/\d+/);
			var post = $x('./ancestor::td', link);
			if((postByNum[rNum] || $x('.//a[@name="' + rNum + '"]')) && post)
				getRefMap(post, post.id.match(/\d+/), rNum);
		}
	});
	for(var rNum in refArr) showRefMap(postByNum[rNum], rNum)
}

function get_cookie(name)
{
	with(document.cookie)
	{
		var regexp=new RegExp("(^|;\\s+)"+name+"=(.*?)(;|$)");
		var hit=regexp.exec(document.cookie);
		if(hit&&hit.length>2) return unescape(hit[2]);
		else return '';
	}
};

function set_cookie(name,value,days)
{
	if(days)
	{
		var date=new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires="; expires="+date.toGMTString();
	}
	else expires="";
	document.cookie=name+"="+value+expires+"; path=/";
}


function save_cookies(id){
	with(document.getElementById(id)) {
		set_cookie("name",name.value, 14);
		set_cookie("email",email.value, 14);
		set_cookie("password",password.value, 14);
	}
}



function get_password(name)
{
	var pass=get_cookie(name);
	if(pass) return pass;

	var chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	var pass='';

	for(var i=0;i<8;i++)
	{
		var rnd=Math.floor(Math.random()*chars.length);
		pass+=chars.substring(rnd,rnd+1);
	}

	return(pass);
}

function insert(text)
{
	var textarea=document.forms.postform2.comment;
	if(textarea)
	{
		if(textarea.createTextRange && textarea.caretPos) // IE
		{
			var caretPos=textarea.caretPos;
			caretPos.text=caretPos.text.charAt(caretPos.text.length-1)==" "?text+" ":text;
		}
		else if(textarea.setSelectionRange) // Firefox
		{
			var start=textarea.selectionStart;
			var end=textarea.selectionEnd;
			textarea.value=textarea.value.substr(0,start)+text+textarea.value.substr(end);
			textarea.setSelectionRange(start+text.length,start+text.length);
		}
		else
		{
			textarea.value+=text+" ";
		}
		textarea.focus();
	}
}

function highlight(post)
{
	var cells=document.getElementsByTagName("td");
	for(var i=0;i<cells.length;i++) if(cells[i].className=="highlight") cells[i].className="reply";

	var reply=document.getElementById("reply"+post);
	if(reply)
	{
		reply.className="highlight";
/*		var match=/^([^#]*)/.exec(document.location.toString());
		document.location=match[1]+"#"+post;*/
		return false;
	}

	return true;
}



function set_stylesheet(styletitle,norefresh)
{
	set_cookie("ochobastyle",styletitle,365);

	var links=document.getElementsByTagName("link");
	var found=false;
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&title)
		{
			links[i].disabled=true; // IE needs this to work. IE needs to die.
			if(styletitle==title) { links[i].disabled=false; found=true; }
		}
	}
	if(!found) set_preferred_stylesheet();
}

function set_preferred_stylesheet()
{
	var links=document.getElementsByTagName("link");
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&title) links[i].disabled=(rel.indexOf("alt")!=-1);
	}
}

function get_active_stylesheet()
{
	var links=document.getElementsByTagName("link");
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&title&&!links[i].disabled) return title;
	}
	return null;
}

function get_preferred_stylesheet()
{
	var links=document.getElementsByTagName("link");
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&rel.indexOf("alt")==-1&&title) return title;
	}
	return null;
}

function set_inputs(id) { with(document.getElementById(id)) {
if(!name.value) name.value=get_cookie("name"); 
if(!email.value) email.value=get_cookie("email"); 
if(!password.value) password.value=get_password("password"); } }
function set_delpass(id) { with(document.getElementById(id)) password.value=get_cookie("password"); }

function do_ban(el)
{
	var reason=prompt("Give a reason for this ban:");
	if(reason) document.location=el.href+"&reason="+encodeURIComponent(reason);
	return false;
}

window.onunload=function(e)
{
	if(style_cookie)
	{
		var title=get_active_stylesheet();
		set_cookie(style_cookie,title,365);
	}
}
function lazyadmin()
{
    var admin=get_cookie("ochobaadmin");
    
    var posts = document.getElementsByClassName('reflink');
    var post;
    var id;
    var pos;
    var tmp;
    var board=document.location.toString().split("/")[3];
    for(var i=0;i<posts.length;i++){
        post = posts[i];
        //Это очень не правильно, but monkey cannot Regexp.
        pos=post.innerHTML.indexOf('No.');
        //alert(post.innerHTML+"\n"+pos);
        if(pos>0 && admin)
        {	
			
			tmp=post.innerHTML.substring(pos+3);
            id=tmp.substring(0,tmp.indexOf('<'));
            post.innerHTML+="[&nbsp;&nbsp;<a title=\"Удалить пост.\" href=\"/"+board+"/delete.pl?delete="+id+"&password=1\" onclick=\"return conf(this)\">D</a>&nbsp;&nbsp;";
          //  post.innerHTML+="<a title=\"Удалить все посты.\" href=\"/"+board+"/admin.pl?do=banpost&post="+id+"&mode=5\" onclick=\"return conf(this)\">DAll</a>&nbsp;&nbsp;";
          //  post.innerHTML+="<a title=\"Забанить&Удалить\" href=\"/"+board+"/admin.pl?do=banpost&post="+id+"&mode=1\" onclick=\"return do_ban(this)\">D&B</a>&nbsp;&nbsp;";
          // post.innerHTML+="<a title=\"Забанить&Удалить Всё\" href=\"/"+board+"/admin.pl?do=banpost&post="+id+"&mode=6\" onclick=\"return do_ban(this)\" onclick=\"return conf(this)\">DAll&B</a>&nbsp;&nbsp;";
            post.innerHTML+="<a title=\"Забанить.\" href=\"/"+board+"/admin.pl?&do=banpost&post="+id+"\" onclick=\"return do_ban(this)\">B</a>&nbsp;&nbsp;";
            post.innerHTML+="<a title=\"Удалить файл.\" href=\"/"+board+"/delete.pl?&delete="+id+"&fileonly=1&password=1\" onclick=\"return conf(this)\">F</a>&nbsp;&nbsp;";
			post.innerHTML+="<a title=\"Показать все посты с этого IP\" href=\"/"+board+"/admin.pl?do=posts&post="+id+"\">S</a>&nbsp;&nbsp;";
			post.innerHTML+='<a title="Закрыть/окрыть" href="/'+board+'/admin.fpl?do=close&thread='+id+'">CL</a>&nbsp;&nbsp;<a title="Прикрепить/открепить" href="/'+board+'/admin.fpl?do=stick&thread='+id+'">ST</a>&nbsp;&nbsp;';
           // post.innerHTML+="<a title=\"Перенести в архив\" href=\"/"+board+"/admin.pl?do=delete&admin="+admin+"&archive=Archive&mode=2&delete="+id+"\" onclick=\"return conf(this)\">A</a>&nbsp;";
			post.innerHTML+="<a title=\"Зашкварить\" href=\"/"+board+"/admin.pl?&do=pe2shock&post="+id+"\"  onclick=\"return conf(this)\">KO</a>&nbsp;&nbsp;";
			post.innerHTML+="<a title=\"Отшкварить\" href=\"/"+board+"/admin.pl?&do=posan&post="+id+"\"  onclick=\"return conf(this)\">OK</a>&nbsp;&nbsp;]";
			
			//>Ответ</a>]
			
			
			
		}

    }
}
function conf(el) {
    if (confirm("Вы уверены в своих действиях?")) {
        document.location = el.href;
	}
    return false;
}
function expand(self,src,n_w,n_h,o_w,o_h)
{
	var element = document.getElementById(self);
	var ssrc="'"+src+"'";
	var sself="'"+self+"'";
	var link="<a href=\"#\" onClick=\"expand("+sself+","+ssrc+","+o_w+","+o_h+","+n_w+","+n_h+"); return false;\">" ;
	var img="<img src=\""+src+"\" width=\""+n_w+"\" height=\""+n_h+"\" class=\"thumb\" >";
	element.innerHTML=link+img;

}
window.onload=function(e)
{
	var match;

	if(match=/#i([0-9]+)/.exec(document.location.toString()))
	if(!document.forms.postform.comment.value)
	insert(">>"+match[1]);

	if(match=/#([0-9]+)/.exec(document.location.toString()))
	highlight(match[1]);
	lazyadmin();
	$each($X('.//td[@class="reply"]'), function(post) {postByNum[post.id.match(/\d+/)] = post});
	doRefPreview();
	doRefMap();
}

function wipe(id,url) {

	var req = false;
  // For Safari, Firefox, and other non-MS browsers
  if (window.XMLHttpRequest) {
    try {
      req = new XMLHttpRequest();
    } catch (e) {
      req = false;
    }
  } else if (window.ActiveXObject) {
    // For Internet Explorer on Windows
    try {
      req = new ActiveXObject("Msxml2.XMLHTTP");
    } catch (e) {
      try {
        req = new ActiveXObject("Microsoft.XMLHTTP");
      } catch (e) {
        req = false;
      }
    }
  }
 var element = document.getElementsByClassName(id)[1];
 if (!element) {
  alert("Bad id " + id);
  return;
 }
  if (req) {
    req.open('GET', url, false);
    req.send(null);
	document.getElementById('02').innerHTML='';
    element.innerHTML =element.innerHTML+ req.responseText;
  } else {
    element.innerHTML ="NotLoaded";
  }
}
if(style_cookie)
{
	var cookie=get_cookie(style_cookie);
	var title=cookie?cookie:get_preferred_stylesheet();
	set_stylesheet(title);
}

//Подгрузка сообщений
function fastload_listen (channel){

var realplexor = new Dklab_Realplexor(
    "http://comet.2--ch.ru"
);

realplexor.subscribe(channel, function(data, id) {

var htmlcode='<table><tbody><tr><td class="doubledash">&gt;&gt;</td><td class="reply" id="reply'+data._id+'"><a name="'+data._id+'>"></a><label><input type="checkbox" name="delete" value="'+data._id+'" /><span class="replytitle">'+data.subject+'</span> ';

if(data.email){htmlcode +='<span class="commentpostername"><a href="'+data.email+'">'+data.name+'</a></span>';}
else{htmlcode +='<span class="commentpostername">'+data.name+'</span>';}
			
if(data.trip){htmlcode +='<span class="postertrip"><a href="'+data.email+'">'+data.trip+'</a></span>';}

htmlcode +=' '+data.date+'</label><span class="reflink"><a href="'+data.parent+'.html#i'+data._id+'" onclick="javascript:insert(\'&gt;&gt;'+data._id+'\')"> No.'+data._id+'</a></span>&nbsp;';

if(data.files.length){htmlcode +='<table><tr>';}
for(var file in data.files) {
	htmlcode +='<td><span class="filesize">Файл: <a target="_blank" href="../'+data.files[file]['filepath']+'">'+data.files[file]['filename']+'</a>(<em>'+data.files[file]['size']+' Кб, '+data.files[file]['width']+'x'+data.files[file]['height']+'</em>)<br />';
	
				if(data.files[file]['thumbnail']){
					htmlcode +='<span id="th_'+data.files[file]['thumbnail']+'"><a href="../'+data.files[file]['filepath']+'"';
					
					if(data.files[file]['theight'] && data.files[file]['twidth']){htmlcode +=' onClick="expand(\'th_'+data.files[file]['thumbnail']+'\',\'/../'+data.files[file]['filepath']+'\','+data.files[file]['width']+','+data.files[file]['height']+','+data.files[file]['twidth']+','+data.files[file]['theight']+'); return false;"';}
					
					htmlcode +='><img src="../'+data.files[file]['thumbnail']+'" width="'+data.files[file]['twidth']+'" height="'+data.files[file]['theight']+'" alt="'+data.files[file]['size']+'" class="thumb" /></a></span>';
				}
				else
				{
						htmlcode +='<div class="nothumb"><a target="_blank" href="'+data.files[file]['image']+'">Нету превью.</a></div>';
				};
				htmlcode +='</span></td>';
};
if(data.files.length){htmlcode +='</tr></table>';}
htmlcode +='<blockquote>'+data.comment+'</blockquote></td></tr></tbody></table>';

document.getElementById('fastload').innerHTML += htmlcode;
	});

realplexor.execute();
}






function threadHide(id)
{
	toggleHidden(id);
	add_to_thread_cookie(id);
}
function threadShow(id)
{
	document.getElementById(id).style.display = "";
	
	var threadInfo = id + "_info";
	var parentform = document.getElementById("delform");
	var obsoleteinfo = document.getElementById(threadInfo);
	obsoleteinfo.setAttribute("id","");
	var clearedinfo = document.createElement("div");
	clearedinfo.style.cssFloat = "left";
	clearedinfo.style.styleFloat = "left"; 
	parentform.replaceChild(clearedinfo,obsoleteinfo);
	clearedinfo.setAttribute("id",threadInfo);
	
	var hideThreadSpan = document.createElement("span");
	var hideThreadLink = document.createElement("a");
	hideThreadLink.setAttribute("href","javascript:threadHide('"+id+"')");
	var hideThreadLinkText = document.createTextNode("Скрыть тред");
	hideThreadLink.appendChild(hideThreadLinkText);
	hideThreadSpan.appendChild(hideThreadLink);
	
	var oldSpan = document.getElementById(id+"_display");
	oldSpan.setAttribute("id","");
	parentform.replaceChild(hideThreadSpan,oldSpan);
	hideThreadLink.setAttribute("id","toggle"+id);
	hideThreadSpan.setAttribute("id",id+"_display");
	hideThreadSpan.style.cssFloat = "right";
	hideThreadSpan.style.styleFloat = "right";
	
	remove_from_thread_cookie(id);
}
function add_to_thread_cookie(id)
{
	var hiddenThreadArray = get_cookie(thread_cookie);
	if (hiddenThreadArray.indexOf(id + ",") != -1)
	{			
		return;
	}
	else
	{
		set_cookie(thread_cookie, hiddenThreadArray + id + ",", 365);
	}
}

function remove_from_thread_cookie(id)
{
	var hiddenThreadArray = get_cookie(thread_cookie);
	var myregexp = new RegExp(id + ",", 'g');
	hiddenThreadArray = hiddenThreadArray.replace(myregexp, "");
	set_cookie(thread_cookie, hiddenThreadArray, 365);
}

function toggleHidden(id)
{
	var id_split = id.split("");
	if (id_split[0] == "t")
	{
		id_split.reverse();
		var shortenedLength = id_split.length - 1;
		id_split.length = shortenedLength;
		id_split.reverse();
	}
	else
	{
		id = "t" + id;
	}
	if (document.getElementById(id))
	{
		document.getElementById(id).style.display = "none";
	}
	var thread_name = id_split.join("");
	var threadInfo = id + "_info";
	if (document.getElementById(threadInfo))
	{
		var hiddenNotice = document.createElement("em");
		var hiddenNoticeText = document.createTextNode("Тред № " + thread_name + " скрыт.");
		hiddenNotice.appendChild(hiddenNoticeText);
		
		var hiddenNoticeDivision = document.getElementById(threadInfo);
		hiddenNoticeDivision.appendChild(hiddenNotice);
	}
	var showThreadText = id + "_display";
	if (document.getElementById(showThreadText)) 
	{
		var showThreadSpan = document.createElement("span");
		var showThreadLink = document.createElement("a");
		showThreadLink.setAttribute("href","javascript:threadShow('"+id+"')");
		var showThreadLinkText = document.createTextNode("Показать тред");
		showThreadLink.appendChild(showThreadLinkText);
		showThreadSpan.appendChild(showThreadLink);
		
		var parentform = document.getElementById("delform");
		var oldSpan = document.getElementById(id+"_display");
		oldSpan.setAttribute("id","");
		parentform.replaceChild(showThreadSpan,oldSpan);
		showThreadLink.setAttribute("id","toggle"+id);
		showThreadSpan.setAttribute("id",id+"_display");
		showThreadSpan.style.cssFloat = "right";
		showThreadSpan.style.styleFloat = "right";
	}
}