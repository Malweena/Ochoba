<include %TMPLDIR%/head.tpl>
		<loop $posts>
		<if !$parent>
			<if @{$files}><br/><table><tr></if>
			<loop $files>
				<td>
				<span class="filesize">Файл: <a target="_blank" href="/<var %SECTION>/<var $filepath>"><var $filename></a>
				(<em><var $size> Кб, <var $width>x<var $height></em>)
				<!--<span class="thumbnailmsg">Изображение будет развёрнуто при нажатии.</span>-->
				<br />
				<if $thumbnail>
					<span id="th_<var $thumbnail>">
					<a href="/<var %SECTION>/<var $filepath>"
					<if $theight and $width> onClick="expand('th_<var $thumbnail>','/<var %SECTION>/<var $filepath>',<var $width>,<var $height>,<var $twidth>,<var $theight>); return false;"</if>>
					<img src="/<var %SECTION>/<var $thumbnail>" width="<var $tn_width>" height="<var $tn_height>" alt="<var $size>" class="thumb" />
					</a>
					</span>
				</else/>
						<div class="nothumb"><a target="_blank" href="<var $image>">Нет превью</a></div>
				</if></span>
				</td>
			</loop>
			<if @{$files}></tr></table></if>

			<a name="<var $_id>"></a>
			<label><input type="checkbox" name="delete" value="<var $_id>" />
			<span class="filetitle"><var $subject></span>
			<if $email><span class="postername"><a href="<var $email>"><var $name></a></span>
			</else/><span class="postername"><var $name></span></if>
			
			<if $trip><span class="postertrip">
			<if $email><a href="<var $email>"><var $trip></a></else/><var $trip></if>
			</span></if>
			<var $date></label>
			
			<span class="reflink">
			<if !%thread><a href="res/<var $_id>.html#i<var $_id>">No.<var $_id></a></if>
			
			<if %thread><a href="<var $_id>.html#i<var $_id>" onclick="javascript:insert('&gt;&gt;<var $_id>')">No.<var $_id></a></if>
			</span>&nbsp;

			<if !%thread>[<a href="res/<var $_id>.html">Ответ</a>]</if>
			
			<blockquote>
			<var $comment>
			<!--<if $abbrev><div class="abbrev">Сообщение слишком большое. Нажмите <a href="<var $parent>.html#<var $_id>">здесь</a> чтобы увидеть его целиком.</div></if>-->
			</blockquote>
			

			<if %REPLIES_PER_THREAD<$postscount >
				<span class="omittedposts">
				Всего <var $postscount> сообщений. Нажмите [Ответ], чтобы увидеть тред целиком.
				</span>
			</if>
		
		</else/>
			<table><tbody><tr><td class="doubledash">&gt;&gt;</td>
			<td class="reply" id="reply<var $_id>">

			<a name="<var $_id>"></a>
			<label><input type="checkbox" name="delete" value="<var $_id>" />
			<span class="replytitle"><var $subject></span>
			<if $email><span class="commentpostername"><a href="<var $email>"><var $name></a></span>
			</else/><span class="commentpostername"><var $name></span></if>
			<if $trip><span class="postertrip">
			
			<if $email><a href="<var $email>"><var $trip></a></else/><var $trip></if>
			
			</span></if>
			<var $date></label>
			<span class="reflink">
			<if !%thread><a href="res/<var $_id>.html#i<var $_id>">No.<var $_id></a></if>
			
			<if %thread><a href="<var $parent>.html#i<var $_id>" onclick="javascript:insert('&gt;&gt;<var $_id>')">No.<var $_id></a></if>
			</span>&nbsp;
			
			<if @{$files}><table><tr></if>
			<loop $files>
				<td>
				<span class="filesize">Файл: <a target="_blank" href="/<var %SECTION>/<var $filepath>"><var $filename></a>
				(<em><var $size> Кб, <var $width>x<var $height></em>)
				<!--<span class="thumbnailmsg">Изображение будет развёрнуто при нажатии.</span>-->
				<br />
				<if $thumbnail>
					<span id="th_<var $thumbnail>">
					<a href="/<var %SECTION>/<var $filepath>"
					<if $theight and $width> onClick="expand('th_<var $thumbnail>','/<var %SECTION>/<var $filepath>',<var $width>,<var $height>,<var $twidth>,<var $theight>); return false;"</if>>
					<img src="/<var %SECTION>/<var $thumbnail>" width="<var $tn_width>" height="<var $tn_height>" alt="<var $size>" class="thumb" />
					</a>
					</span>
				</else/>
						<div class="nothumb"><a target="_blank" href="<var $image>">Нет превью</a></div>
				</if></span>
				</td>
			</loop>
			<if @{$files}></tr></table></if>
			<blockquote>
			<var $comment>
			<if $abbrev><div class="abbrev">Сообщение слишком большое. Нажмите <a href="<var $parent>.html#<var $_id>">здесь</a> чтобы увидеть его целиком.</div></if>
			</blockquote>

			</td></tr></tbody></table>
			
		</if>
	</loop>
	<br clear="left" /><hr />
<include %TMPLDIR%/foot.tpl>