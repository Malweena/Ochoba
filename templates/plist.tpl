<include %TMPLDIR%/head.tpl>
<include %TMPLDIR%/admin_head.tpl>
<p>
<form action="">
<div class="managehead">IP: <input name="ip" value="<var $ip>"/><input type="submit" value="Найти"/></div>
<input type="hidden" name="do" value="posts"/>
</form>
</p>
<form action="delete.fpl?password=1" method="post">
<input type="hidden" name="password" value="1" />

<div class="delbuttons">
<input type="submit" value="Удалить" />
<input type="reset" value="Сброс" />
[<label><input type="checkbox" name="fileonly" value="1" />Только файлы</label>]
</div>
<center>Страницы: <aloop $pages>[<a href="admin.fpl?do=posts&page=<var $_>"><var $_></a>]</loop></center>
<br>
<table style="white-space: nowrap" width="98%" align="center"><tbody>
<!--<tr class="managehead">Управление постами</tr>-->
<loop $posts>
	<tr class="row<if %i++ and %i/2==int(%i/2)>2</else/>1</if>"<if !$parent> id = "oppost"</if>>
	
	<td>
	<label><input type="checkbox" name="delete" value="<var $_id>" /><big><b><var $_id></b></big> 
	<if $sticked><img src="/sticked.png" alt="sticked"/></if>
	<if $closed><img src="/closed.png" alt="closed"/></if>
	&nbsp;&nbsp;</label>
	</td>

	<td width="200"><var $date></td>
	
	<td><perleval 
	if(20< length($subject) && $subject=~m/^<a href=/i)
		{$subject=substr($subject,0,20)."..."; }
	elsif(10< length($subject))	
		{$subject=substr($subject,0,10)."..."} />
	<var $subject>
	</td>
	
	<td width="200"><perleval 
	if(10< length($name) && $name=~m/href=/i)
		{$name=substr($name,0,10)."..."; }
	elsif(6< length($name))	
		{$name=substr($name,0,6)."..."} />	
	<b><var $name><var $trip></b>
	</td>
	
	<td><perleval 
	if(75< length($comment) && $comment=~m/href=/i)
		{$comment=substr($comment,0,150)."...";}
	elsif(25< length($comment))
		{$comment=substr($comment,0,50)."..."} />
	<if !$_id>Это системный пост. Не удаляйте его!</if>
	<var $comment>
	</td>
	
	<td align="right" width="120">
	<var $ip>
	</td>
	
	<td width="175">
	<div class="adminbar">
		<if !$parent>
		[<a title="Закрыть/окрыть" href="admin.fpl?do=close&thread=<var $_id>">Close</a>]
		[<a title="Прикрепить/открепить" href="admin.fpl?do=stick&thread=<var $_id>">Stick</a>]</if>
		
		[<a title="Удалить" href="delete.fpl?delete=<var $_id>&password=1">D</a>]
		<!--[<a title="Удалить все посты с этого ip" href="admin.fpl?do=dall&post=<var $_id>">DAll</a>]
		[<a title="Удалить этот пост и забанить" href="admin.fpl?do=delban&post=<var $_id>" onclick="return do_ban(this)">D&B</a>]
		[<a title="Удалить все и забанить" href="admin.fpl?do=dallban&post=<var $_id>" onclick="return do_ban(this)">DAll&B</a>]-->
		[<a title="Забанить" href="admin.fpl?do=banpost&post=<var $_id>" onclick="return do_ban(this)">B</a>]
		[<a title="Удалить файлы" href="delete.fpl?delete=<var $_id>&fileonly=1&password=1">F</a>]
		[<a title="Найти все посты с этого ip" href="admin.fpl?do=posts&post=<var $_id>">S</a>]
	</div>	
	</td>
	</tr>
	
	<if $files and @{$files}><tr class="row<if %i/2==int(%i/2)>2</else/>1</if>"></if>
	
	<loop $files>
		<td><small>
		<a href="/<var %SECTION>/<var $filepath>"><var $filepath></a><br />
		<a href="/<var %SECTION>/<var $filepath>"><img src="/<var %SECTION>/<var $thumbnail>" style="max-height:100px; max-width:100px; border: 1px solid #212121;" /></a><br />
		(<var $size> кб, <var $width>x<var $height>)&nbsp;
		</small></td>	
	</loop>
	
	<if $files and @{$files}></tr></if>
	
</loop>

</tbody></table>

<center>Страницы: <aloop $pages>[<a href="admin.fpl?do=posts&page=<var $_><if $ip>&ip=<var $ip></if>"><var $_></a>]</loop></center>
<div class="delbuttons">
<input type="submit" value="Удалить" />
<input type="reset" value="Сброс" />
[<label><input type="checkbox" name="fileonly" value="1" />Только файлы</label>]
</div>

</form>
<include %TMPLDIR%/foot.tpl>