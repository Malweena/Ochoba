<include %TMPLDIR%/head.tpl>

	
	
<form action="/<var %SECTION>/search.fpl" method="post" style="padding:15px 10px; float:left; ">
	<div class="postblock">Поиск: 
	<input name="search" size="35" value="<var $search>"/>
	<input type="submit" value="Найти" />
	</div>
	</form><div style="padding:15px 10px; float:right; "> [<a href="/<var %SECTION>/0.memhtml">Назад</a>]</div><hr style="clear:left;"/>
	
	<loop $posts>
		<if !$parent>
			

			<a name="<var $_id>"></a>
			<label>
			<span class="filetitle"><var $subject></span>
			<if $email><span class="postername"><a href="<var $email>"><var $name></a></span>
			</else/><span class="postername"><var $name></span></if>
			
			<if $trip><span class="postertrip"><var $trip></span></if>
			<var $date></label>
			
			<span class="reflink">
			<a href="res/<var $_id>.html#i<var $_id>">No.<var $_id></a></span>
			[<a href="res/<var $_id>.html">Ответ</a>]
			
			
			<if $youtube><br/>
			<iframe title="YouTube video player" width="300" height="241" src="http://www.youtube.com/embed/<var $youtube>" frameborder="0"></iframe>
			</if>
			
			<if 1<@{$files} and %td=1 ><table><tr></if>
			<loop $files>
				<if %td><td></else/><br/></if>
				<span class="filesize">Файл: <a target="_blank" href="/<var %SECTION>/<var $filepath>"><var $filename></a>
				(<em><var $size> Кб, <var $width>x<var $height></em>)
				<!--<span class="thumbnailmsg">Изображение будет развёрнуто при нажатии.</span>-->
				<br />
				<if $thumbnail>
					<span id="th_<var $thumbnail>">
					<a href="/<var %SECTION>/<var $filepath>"
					<if $theight and $twidth> onClick="expand('th_<var $thumbnail>','/<var %SECTION>/<var $filepath>',<var $width>,<var $height>,<var $twidth>,<var $theight>); return false;"</if>>
					<img src="/<var %SECTION>/<var $thumbnail>" width="<var $twidth>" height="<var $theight>" alt="<var $size>" class="thumb" />
					</a>
					</span>
				</else/>
						<div class="nothumb"><a target="_blank" href="<var $filepath>">Нет превью</a></div>
				</if></span>
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
		
		</else/>
			<table><tbody><tr><td class="doubledash">&gt;&gt;</td>
			<td class="reply" id="reply<var $_id>">

			<a name="<var $_id>"></a>
			<label>
			<span class="replytitle"><var $subject></span>
			<if $email><span class="commentpostername"><a href="<var $email>"><var $name></a></span>
			</else/><span class="commentpostername"><var $name></span></if>
			<if $trip><span class="postertrip"><var $trip></span></if>
			<var $date></label>
			<span class="reflink">
			<a href="res/<var $parent>.html#i<var $_id>">No.<var $_id></a></span>
			
			<if $youtube><br/>
			<iframe title="YouTube video player" width="300" height="241" src="http://www.youtube.com/embed/<var $youtube>" frameborder="0"></iframe>
			</if>
			
			<if 1<@{$files} and %td=1 ><table><tr></if>
			<loop $files>
				<if %td><td></else/><br/></if>
				<span class="filesize">Файл: <a target="_blank" href="/<var %SECTION>/<var $filepath>"><var $filename></a>
				(<em><var $size> Кб, <var $width>x<var $height></em>)
				<!--<span class="thumbnailmsg">Изображение будет развёрнуто при нажатии.</span>-->
				<br />
				<if $thumbnail>
					<span id="th_<var $thumbnail>">
					<a href="/<var %SECTION>/<var $filepath>"
					<if $theight and $twidth> onClick="expand('th_<var $thumbnail>','/<var %SECTION>/<var $filepath>',<var $width>,<var $height>,<var $twidth>,<var $theight>); return false;"</if>>
					<img src="/<var %SECTION>/<var $thumbnail>" width="<var $twidth>" height="<var $theight>" alt="<var $size>" class="thumb" />
					</a>
					</span>
				</else/>
						<div class="nothumb"><a target="_blank" href="<var $filepath>">Нет превью</a></div>
				</if></span>
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
<include %TMPLDIR%/foot.tpl>