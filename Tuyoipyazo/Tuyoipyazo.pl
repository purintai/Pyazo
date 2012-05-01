#!/usr/bin/perl
use base qw(Wx::App);

sub OnInit
{
	my $s = shift();

	my $MainFrame = Tuyoipyazo::MainFrame->new();
	$MainFrame->Show(1);

	return(1);
}

__PACKAGE__->new()->MainLoop();

exit(0);

package Tuyoipyazo::MainFrame;
use 5.10.0;
use vars qw($B $C $D);
use Config::Tiny;
use Win32::API;
use Win32::API::Callback;
use Win32::API::Struct;
use Win32::Clipboard;
use Win32::Screenshot;
use Wx qw(:everything);
use base qw(Wx::Frame);
use constant SM_XVIRTUALSCREEN =>76;
use constant SM_YVIRTUALSCREEN =>77;
use constant SM_CXVIRTUALSCREEN =>78;
use constant SM_CYVIRTUALSCREEN =>79;
use constant VK_ESCAPE =>0x1b;
use constant VK_1 =>0x31;
use constant VK_9 =>0x39;
use constant N_DRAG_BORDERSIZE =>5;
use constant N_DRAG_SELECTION =>0;
use constant N_DRAG_MOVE =>1;

BEGIN
{
	$C = Config::Tiny->read("Tuyoipyazo.conf") // Config::Tiny->new();
	$D = {};

	Win32::API->Import(qw(USER32 ClientToScreen NS N));
	Win32::API->Import(qw(USER32 EnableWindow NN N));
	Win32::API->Import(qw(USER32 EnumDisplayMonitors NPKN N));
	Win32::API->Import(qw(USER32 EnumWindows KN N));
	Win32::API->Import(qw(USER32 GetClientRect NS N));
	Win32::API->Import(qw(USER32 GetMonitorInfo NS N));
	Win32::API->Import(qw(USER32 GetSystemMetrics N N));
	Win32::API->Import(qw(USER32 GetWindowRect NS N));
	Win32::API->Import(qw(USER32 IsWindowVisible N N));
	Win32::API->Import(qw(USER32 WindowFromPoint NN N));

	Win32::API::Struct->typedef(qw(
		MONITORINFO
		DWORD cbSize
		RECT rcMonitor
		RECT rcWork
		DWORD dwFlags
	));
	Win32::API::Struct->typedef(qw(
		MONITORINFOEX
		DWORD cbSize
		RECT rcMonitor
		RECT rcWork
		DWORD dwFlags
		TCHAR szDevice[32]
	));
	Win32::API::Struct->typedef(qw(
		POINT
		LONG x
		LONG y
	));
	Win32::API::Struct->typedef(qw(
		RECT
		LONG left
		LONG top
		LONG right
		LONG bottom
	));
}

sub new
{
	my @geom = (
		GetSystemMetrics(SM_XVIRTUALSCREEN),
		GetSystemMetrics(SM_YVIRTUALSCREEN),
		GetSystemMetrics(SM_CXVIRTUALSCREEN),
		GetSystemMetrics(SM_CYVIRTUALSCREEN),
	);

	my $s = shift()->SUPER::new(
		undef,
		-1,
		__PACKAGE__,
		[@geom[0,1]],
		[@geom[2,3]],
		wxFRAME_NO_TASKBAR|wxNO_BORDER|wxSTAY_ON_TOP,
	);
	$s->SetBackgroundColour(wxBLACK);
	$s->SetTransparent(0xff * 0.50);

	$s->{Mask} = Wx::Panel->new(
		$s,
		-1,
		[0,0],
		[0,0],
	);
	#$s->{Mask}->SetBackgroundColour(wxGREEN);
	#$s->{Mask}->SetBackgroundColour(wxBLUE);
	$s->{Mask}->SetBackgroundColour(wxCYAN);

	sub onKeyDown
	{
		my $s = shift();
		my $e = shift();

		given($e->GetKeyCode()){
			printf("Keydown VK_%02X\n",$_);

			when(VK_ESCAPE){
				($s->GetParent() // $s)->Close();
			}
			when([VK_1..VK_9]){
				EnumDisplayMonitors(
					0,
					0,
					Win32::API::Callback->new(sub{
						my $hMonitor = shift();
						my $hdcMonitor = shift();
						my $lprcMonitor = shift();
						my $dwData = shift();
						state $i = 0;

						if(++$i == $dwData){
							my $lpmi = Win32::API::Struct->new(MONITORINFOEX);
							$lpmi->{cbSize} = $lpmi->sizeof();

							GetMonitorInfo($hMonitor,$lpmi);

							$D->{xld} = $lpmi->{rcMonitor}->{left} - GetSystemMetrics(SM_XVIRTUALSCREEN);
							$D->{yld} = $lpmi->{rcMonitor}->{top} - GetSystemMetrics(SM_YVIRTUALSCREEN);
							$D->{xlu} = $lpmi->{rcMonitor}->{right} - GetSystemMetrics(SM_XVIRTUALSCREEN);
							$D->{ylu} = $lpmi->{rcMonitor}->{bottom} - GetSystemMetrics(SM_YVIRTUALSCREEN);

							return($i = 0);
						}else{
							return(1);
						}
					},qw(NNPN N)),
					$_ - 0x30,
				);

				my @geom = (
					(sort{$a <=> $b}(@{$D}{qw(xld xlu)}))[0],
					(sort{$a <=> $b}(@{$D}{qw(yld ylu)}))[0],
					abs($D->{xlu} - $D->{xld}),
					abs($D->{ylu} - $D->{yld}),
				);
				($s->GetParent() // $s)->{Mask}->SetSize(Wx::Rect->new(@geom));
			}
		}
		return();
	}

	sub onLeftDown
	{
		my $s = shift();
		my $e = shift();

		$D->{xld} = $e->GetPosition()->x();
		$D->{yld} = $e->GetPosition()->y();

		if(!defined($s->GetParent())){
			$D->{handling} = N_DRAG_SELECTION;
		}else{
			$D->{handling} = N_DRAG_MOVE;
		}
		return();
	}

	sub onLeftUp
	{
		my $s = shift();
		my $e = shift();

		$D->{xlu} = $e->GetPosition()->x() + ($s->GetParent() ? $s->GetPosition()->x() : 0);
		$D->{ylu} = $e->GetPosition()->y() + ($s->GetParent() ? $s->GetPosition()->y() : 0);

		given($D->{handling}){
			when(N_DRAG_SELECTION){
				my @geom = (
					(sort{$a <=> $b}(@{$D}{qw(xld xlu)}))[0],
					(sort{$a <=> $b}(@{$D}{qw(yld ylu)}))[0],
					abs($D->{xlu} - $D->{xld}),
					abs($D->{ylu} - $D->{yld}),
				);
				($s->GetParent() // $s)->{Mask}->SetSize(Wx::Rect->new(@geom));
				printf("handling(%d): %d.%d - %d.%d (%dx%d+%d+%d)\n",$_,@{$D}{qw(xld yld xlu ylu)},@geom[2,3,0,1]);
			}
			when(N_DRAG_MOVE){
				my @geom = (
					$D->{xlu} - $D->{xld},
					$D->{ylu} - $D->{yld},
					($s->GetParent() // $s)->{Mask}->GetRect()->width(),
					($s->GetParent() // $s)->{Mask}->GetRect()->height(),
				);
				($s->GetParent() // $s)->{Mask}->SetSize(Wx::Rect->new(@geom));
			}
		}
		return();
	}

	sub onLeftDoubleClick
	{
		my $s = shift();
		my $e = shift();

		my @geom = (
			($s->GetParent() // $s)->{Mask}->GetRect()->x() + ($s->GetParent() ? $s->GetParent()->GetPosition()->x() : 0),
			($s->GetParent() // $s)->{Mask}->GetRect()->y() + ($s->GetParent() ? $s->GetParent()->GetPosition()->y() : 0),
			($s->GetParent() // $s)->{Mask}->GetRect()->width(),
			($s->GetParent() // $s)->{Mask}->GetRect()->height(),
		);
		($s->GetParent() // $s)->Show(0);
		#my $bin = Win32::Screenshot::CaptureRect(@geom)->ImageToBlob(magick =>"jpg");
		my $bin = Win32::Screenshot::CaptureRect($geom[0],$geom[1],$geom[2],$geom[3])->ImageToBlob(magick =>"jpg");
		printf("Captured(): %dx%d+%d+%d\n",@geom[2,3,0,1]);

		my $sub = require("libdropbox.pl");
		do{
			my($r,@r) = $sub->(\$bin,"jpg");
			if(defined($r[0])){
				Win32::Clipboard->new()->Set($r[0]);
			}
		}while($r);

		($s->GetParent() // $s)->Close();
		return();
	}

	sub onRightDown
	{
		my $s = shift();
		my $e = shift();

		my $x = $e->GetPosition()->x() + GetSystemMetrics(SM_XVIRTUALSCREEN);
		my $y = $e->GetPosition()->y() + GetSystemMetrics(SM_YVIRTUALSCREEN);

		EnumWindows(
			Win32::API::Callback->new(sub{
				my $hwnd = shift();
				my $lParam = shift();
				state $i = 0;

				if(!IsWindowVisible($hwnd)){
					return(1);
				}

				my $lpRect = Win32::API::Struct->new(RECT);
				GetWindowRect($hwnd,$lpRect);

				if($i++ && $x >= $lpRect->{left} && $x <= $lpRect->{right} && $y >= $lpRect->{top} && $y <= $lpRect->{bottom}){
					GetClientRect($hwnd,$lpRect);

					my $lpPoint = Win32::API::Struct->new(POINT);
					$lpPoint->{x} = $lpRect->{left};
					$lpPoint->{y} = $lpRect->{top};
					ClientToScreen($hwnd,$lpPoint);
					$D->{xlu} = $lpPoint->{x} - GetSystemMetrics(SM_XVIRTUALSCREEN);
					$D->{ylu} = $lpPoint->{y} - GetSystemMetrics(SM_YVIRTUALSCREEN);
					$D->{xld} = $lpRect->{right} + $D->{xlu};
					$D->{yld} = $lpRect->{bottom} + $D->{ylu};

					return($i = 0);
				}else{
					return(1);
				}
			},qw(NN N)),
			0,
		);

		my @geom = (
			(sort{$a <=> $b}(@{$D}{qw(xld xlu)}))[0],
			(sort{$a <=> $b}(@{$D}{qw(yld ylu)}))[0],
			abs($D->{xlu} - $D->{xld}),
			abs($D->{ylu} - $D->{yld}),
		);
		($s->GetParent() // $s)->{Mask}->SetSize(Wx::Rect->new(@geom));

		return();
	}

	sub onMouseMove
	{
		my $s = shift();
		my $e = shift();

		if($e->Dragging()){
			return(&onLeftUp($s,$e));
		}elsif(defined($s->GetParent())){
			my $_w = $e->GetPosition()->x();
			my $_n = $e->GetPosition()->y();
			my $_e = $s->GetRect()->width() - $e->GetPosition()->x();
			my $_s = $s->GetRect()->height() - $e->GetPosition()->y();
			printf("%d.%d.%d.%d\n",$_w,$_n,$_e,$_s);

			if($_w <= N_DRAG_BORDERSIZE && $_n <= N_DRAG_BORDERSIZE){
				$s->GetParent()->SetCursor(Wx::Cursor->new(wxCURSOR_SIZENWSE));
			}elsif($_e <= N_DRAG_BORDERSIZE && $_s <= N_DRAG_BORDERSIZE){
				$s->GetParent()->SetCursor(Wx::Cursor->new(wxCURSOR_SIZENWSE));
			}elsif($_n <= N_DRAG_BORDERSIZE && $_e <= N_DRAG_BORDERSIZE){
				$s->GetParent()->SetCursor(Wx::Cursor->new(wxCURSOR_SIZENESW));
			}elsif($_w <= N_DRAG_BORDERSIZE && $_s <= N_DRAG_BORDERSIZE){
				$s->GetParent()->SetCursor(Wx::Cursor->new(wxCURSOR_SIZENESW));
			}elsif($_w <= N_DRAG_BORDERSIZE){
				$s->GetParent()->SetCursor(Wx::Cursor->new(wxCURSOR_SIZEWE));
			}elsif($_e <= N_DRAG_BORDERSIZE){
				$s->GetParent()->SetCursor(Wx::Cursor->new(wxCURSOR_SIZEWE));
			}elsif($_n <= N_DRAG_BORDERSIZE){
				$s->GetParent()->SetCursor(Wx::Cursor->new(wxCURSOR_SIZENS));
			}elsif($_s <= N_DRAG_BORDERSIZE){
				$s->GetParent()->SetCursor(Wx::Cursor->new(wxCURSOR_SIZENS));
			}else{
				$s->GetParent()->SetCursor(Wx::Cursor->new(wxCURSOR_ARROW));
			}
		}else{
			$s->SetCursor(Wx::Cursor->new(wxCURSOR_ARROW));
		}
		return();
	}

	$s->Wx::Event::EVT_KEY_DOWN(\&onKeyDown);
	$s->Wx::Event::EVT_LEFT_DOWN(\&onLeftDown);
	$s->Wx::Event::EVT_LEFT_UP(\&onLeftUp);
	$s->Wx::Event::EVT_RIGHT_DOWN(\&onRightDown);
	$s->Wx::Event::EVT_MOTION(\&onMouseMove);
	$s->{Mask}->Wx::Event::EVT_KEY_DOWN(\&onKeyDown);
	$s->{Mask}->Wx::Event::EVT_LEFT_DOWN(\&onLeftDown);
	$s->{Mask}->Wx::Event::EVT_LEFT_UP(\&onLeftUp);
	$s->{Mask}->Wx::Event::EVT_LEFT_DCLICK(\&onLeftDoubleClick);
	$s->{Mask}->Wx::Event::EVT_RIGHT_DOWN(\&onRightDown);
	$s->{Mask}->Wx::Event::EVT_MOTION(\&onMouseMove);

	return($s);
}
