<include %TMPLDIR%/head.tpl>

<if %thread>
	<script type="text/javascript">fastload_listen('<var %SECTION>_<var $thread>');</script>
	[<a href="/<var %SECTION>/0.memhtml">Назад</a>]
	<div class="theader">Ответ:</div>
</if>

<if %REPLIES and !%closed>
	<div class="postarea">
	<form id="postform" action="/<var %SECTION>/post.fpl" method="post" enctype="multipart/form-data">

	<input type="hidden" name="task" value="post" />
	<if $thread><input type="hidden" name="parent" value="<var $thread>" /></if>
	<if %FORCED_ANON><input type="hidden" name="name" /></if>

	<table><tbody>
	<if !%FORCED_ANON><tr><td class="postblock">Имя</td><td><input type="text" name="name" size="28" /></td></tr></if>
	<tr><td class="postblock">E-mail</td><td><input type="text" name="email" size="28" /></td></tr>
	<tr><td class="postblock">Тема</td><td><input type="text" name="subject" size="35" />
	<input type="submit" value="Отправить" onClick="save_cookies('postform');"/></td></tr>
	<tr><td class="postblock">Отправить</td><td><textarea name="comment" cols="48" rows="4"></textarea></td></tr>
	
	<if %ENABLE_CAPTCHA>
		<tr><td class="postblock">Код подтверждения</td><td>
		 <script type="text/javascript"> window.captchaShowed = 0; function show_captcha() { if(window.captchaShowed == 0) { var Div = document.getElementById("captchadiv"); Div.innerHTML = '<img alt="обновить captcha" src="/<var %SECTION>/captcha.fpl" id="imgcaptcha" />'; window.captchaShowed = 1; } } </script> 

		 <input type="text" name="captcha" size="10" onfocus="show_captcha()"><font size="2"> </font><div id="captchadiv" style="display:inline;"><font size="2"> <script type="text/javascript"> var ua = navigator.userAgent.toLowerCase(); if (ua.indexOf("opera mini") != -1) { document.write('<img alt="обновить captcha" src="/<var %SECTION>/captcha.fpl" id="imgcaptcha" />'); } </script> 
		 <noscript>У вас отключён JavaScript.</noscript>Кликните в поле ввода капчи для ее показа</font> 
		 </td></tr>
	</if>
<if %UPFILES>
		<tr><td class="postblock">Файлы</td><td><input name="file" type="file" class="multi" maxlength="<var %UPFILES>" accept="<aloop [keys %{%FILETYPES}]>|<var $_></loop>" />
		</td></tr>
	</if>
<if %YOUTUBE><tr><td class="postblock">Youtube:</td><td><input type="test" name="youtube" size="35" />
		</td></tr></if>

	<tr><td class="postblock">Пароль</td><td><input type="password" name="password" size="8" /> (Для удаления поста или файла)</td></tr>
	
	<tr><td colspan="2">
	<div class="rules"></div></td></tr>
	</tbody></table></form></div>
	<script type="text/javascript">set_inputs("postform")</script>

	<hr /> 

        <if !$thread>
        <script type="text/javascript">
                var hiddenThreads=get_cookie(thread_cookie);
        </script>
        </if>
</if>


<form id="delform" action="/<var %SECTION>/delete.fpl" method="post">
<loop $threads>
<perleval %sticked=$sticked; %closed=$closed; %postscount=$postscount />
	<loop $posts>
		<if !$parent>
                        <div id="t<var $_id>_info" style="float:left"></div>
                        <if !$thread><span id="t<var $_id>_display" style="float:right"><a href="javascript:threadHide('t<var $_id>')" id="togglet<var $_id>">Скрыть тред</a><ins><noscript><br/>(у вас отключен Javascript)</noscript></ins></span></if>
                        <div id="t<var $_id>">			

			<a name="<var $_id>"></a>
			<label><input type="checkbox" name="delete" value="<var $_id>" />
			<span class="filetitle"><var $subject></span>
			<if $email><span class="postername"><a href="<var $email>"><var $name></a></span>
			</else/><span class="postername"><var $name></span></if>
			
			<if $trip><span class="postertrip"><var $trip></span></if>
			<var $date></label>
			
			<span class="reflink">
			<if !%thread><a href="res/<var $_id>.html#i<var $_id>">No.<var $_id></a></if>
			
			<if %thread><a href="<var $_id>.html#i<var $_id>" onclick="javascript:insert('&gt;&gt;<var $_id>')">No.<var $_id></a></if>
			</span>&nbsp;
			
			
			<if !%thread>[<a href="res/<var $_id>.html">Ответ</a>]</if>
			<if %closed><img src="/closed.png" alt="closed"/></if>
			<if %sticked><img src="/sticked.png" alt="sticked"/></if>
			
			<if $youtube><br/>
			<iframe title="YouTube video player" width="300" height="241" src="http://www.youtube.com/embed/<var $youtube>" frameborder="0"></iframe>
			</if>
			
			<if 1<@{$files} and %td=1 ><table class="postfiles"><tr></if>
			<loop $files>
				<if %td><td></else/><br/></if>
				<span class="filesize">Файл: <a target="_blank" href="/<var %SECTION>/<var $filepath>"><var $filename></a>
				(<em><var $size> Кб, <var $width>x<var $height></em>)</span>
				<if !%td><span class="thumbnailmsg">Изображение будет развёрнуто при нажатии.</span></if><br/>
				<if $thumbnail>
					<span id="th_<var $thumbnail>">
					<a href="/<var %SECTION>/<var $filepath>"
					<if $theight and $twidth> onClick="expand('th_<var $thumbnail>','/<var %SECTION>/<var $filepath>',<var $width>,<var $height>,<var $twidth>,<var $theight>); return false;"</if>>
					<img src="/<var %SECTION>/<var $thumbnail>" width="<var $twidth>" height="<var $theight>" alt="<var $size>" class="thumb" />
					</a>
					</span>
				</else/>
						<div class="nothumb"><a target="_blank" href="<var $filepath>">Нет превью</a></div>
				</if>
				<if %td></td></if>
			</loop>
			<if 1<@{$files}></tr></table></if>
			<perleval %td=0 /> 
			
			<blockquote>
			<var $comment>
			<!--<if $abbrev><div class="abbrev">Сообщение слишком большое. Нажмите <a href="<var $parent>.html#<var $_id>">здесь</a> чтобы увидеть его целиком.</div></if>-->
			</blockquote>
			

			<if !%thread and %REPLIES_PER_THREAD < %postscount>
				<span class="omittedposts">
				Всего <var %postscount> сообщений. Нажмите [Ответ], чтобы увидеть тред целиком.
				</span>
			</if>
                        <if !$thread>
                                <script type="text/javascript">
                                        if (hiddenThreads.indexOf('t<var $_id>,') != -1)
                                        {
                                                toggleHidden('t<var $_id>');   
                                        }
                                </script>
                        </if>
		</else/>
			<table><tbody><tr><td class="doubledash">&gt;&gt;</td>
			<td class="reply" id="reply<var $_id>">

			<a name="<var $_id>"></a>
			<label><input type="checkbox" name="delete" value="<var $_id>" />
			<span class="replytitle"><var $subject></span>
			<if $email><span class="commentpostername"><a href="<var $email>"><var $name></a></span>
			</else/><span class="commentpostername"><var $name></span></if>
			<if $trip><span class="postertrip"><var $trip></span></if>
			<var $date></label>
			<span class="reflink">
			<if !%thread><a href="res/<var $parent>.html#i<var $_id>">No.<var $_id></a></if>
			
			<if %thread><a href="<var $parent>.html#i<var $_id>" onclick="javascript:insert('&gt;&gt;<var $_id>')">No.<var $_id></a></if>
			</span>&nbsp;
			
			<if $youtube><br/>
			<iframe title="YouTube video player" width="300" height="241" src="http://www.youtube.com/embed/<var $youtube>" frameborder="0"></iframe>
			</if>
			
			<if 1<@{$files} and %td=1 ><table class="postfiles"><tr></if>
			<loop $files>
				<if %td><td></else/><br/></if>
				<span class="filesize">Файл: <a target="_blank" href="/<var %SECTION>/<var $filepath>"><var $filename></a>
				(<em><var $size> Кб, <var $width>x<var $height></em>)</span>
				<if !%td><span class="thumbnailmsg">Изображение будет развёрнуто при нажатии.</span></if><br/>
				<if $thumbnail>
					<span id="th_<var $thumbnail>">
					<a href="/<var %SECTION>/<var $filepath>"
					<if $theight and $twidth> onClick="expand('th_<var $thumbnail>','/<var %SECTION>/<var $filepath>',<var $width>,<var $height>,<var $twidth>,<var $theight>); return false;"</if>>
					<img src="/<var %SECTION>/<var $thumbnail>" width="<var $twidth>" height="<var $theight>" alt="<var $size>" class="thumb" />
					</a>
					</span>
				</else/>
						<div class="nothumb"><a target="_blank" href="<var $filepath>">Нет превью</a></div>
				</if>
				<if %td></td></if>
			</loop>
			<if 1<@{$files}></tr></table></if>
			<perleval %td=0 /> 
			<blockquote>
			<var $comment>
			<!--<if $abbrev><div class="abbrev">Сообщение слишком большое. Нажмите <a href="<var $parent>.html#<var $_id>">здесь</a> чтобы увидеть его целиком.</div></if>-->
			</blockquote>

			</td></tr></tbody></table>
			
		</if>
	</loop>
	</div>  
	<if %thread><div id="fastload"><!--сюда подгружаются посты--></div></if>
	<br clear="left" /><hr />
	<perleval %postscount=0 />
</loop>


<table class="userdelete"><tbody><tr><td>
<input type="hidden" name="task" value="delete" />
Удалить пост [<label><input type="checkbox" name="fileonly" value="on" />Только файл</label>]<br />
Пароль <input type="password" name="password" size="8" />
<input value="Удалить" type="submit" /></td></tr></tbody></table>
</form>
<script type="text/javascript">set_delpass("delform");</script>

<if %REPLIES and $thread and !%closed>
	<div class="postarea">
	<form id="postform2" action="/<var %SECTION>/post.fpl" method="post" enctype="multipart/form-data">

	<input type="hidden" name="task" value="post" />
	<if $thread><input type="hidden" name="parent" value="<var $thread>" /></if>
	<if %FORCED_ANON><input type="hidden" name="name" /></if>

	<table><tbody>
	<if !%FORCED_ANON><tr><td class="postblock">Имя</td><td><input type="text" name="name" size="28" /></td></tr></if>
	<tr><td class="postblock">E-mail</td><td><input type="text" name="email" size="28" /></td></tr>
	<tr><td class="postblock">Тема</td><td><input type="text" name="subject" size="35" />
	<input type="submit" value="Отправить" onClick="save_cookies('postform2');"/></td></tr>
	<tr><td class="postblock">Отправить</td><td><textarea name="comment" cols="48" rows="4"></textarea></td></tr>
	
	<if %ENABLE_CAPTCHA>
		<tr><td class="postblock">Код подтверждения</td><td>
		 <script type="text/javascript"> window.captcha2Showed = 0; function show_2captcha() { if(window.captchaShowed == 0) { var Div = document.getElementById("captchadiv2"); Div.innerHTML = '<img alt="обновить captcha" src="/<var %SECTION>/captcha.fpl" id="imgcaptcha2" />'; window.captcha2Showed = 1; } } </script> 

		 <input type="text" name="captcha" size="10" onfocus="show_2captcha()"><font size="2"> </font><div id="captchadiv2" style="display:inline;"><font size="2"> <script type="text/javascript"> var ua = navigator.userAgent.toLowerCase(); if (ua.indexOf("opera mini") != -1) { document.write('<img alt="обновить captcha" src="/<var %SECTION>/captcha.fpl" id="imgcaptcha2" />'); } </script> 
		 <noscript>У вас отключён JavaScript.</noscript>Кликните в поле ввода капчи для ее показа</font> 
		 </td></tr>
	</if>
	
<if %UPFILES>
		<tr><td class="postblock">Файлы</td><td><input name="file" type="file" class="multi" maxlength="<var %UPFILES>" accept="<aloop [keys %{%FILETYPES}]>|<var $_></loop>" />
		</td></tr>
	</if>
<if %YOUTUBE><tr><td class="postblock">Youtube:</td><td><input type="test" name="youtube" size="35" />
		</td></tr></if>
	<tr><td class="postblock">Пароль</td><td><input type="password" name="password" size="8" /> (Для удаления поста или файла)</td></tr>
	
	<tr><td colspan="2">
	<div class="rules"></div></td></tr>
	</tbody></table></form></div>
	
<script type="text/javascript">set_inputs("postform2")</script>
	<hr /> 
	
</if>

<if !$thread>
	<table border="1"><tbody><tr><td>

	<aloop $pages>
		<if $_==$current>[<var $_>]
		</else/>[<a href="/<var %SECTION>/<var $_>.memhtml"><var $_></a>]</if>
	</loop>

	</td><td>

	</td></tr></tbody></table><br clear="all" />
</if>


<include %TMPLDIR%/foot.tpl>