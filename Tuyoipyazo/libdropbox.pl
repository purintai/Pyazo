package Tuyoipyazo::MainFrame::Dropbox;
use 5.10.0;
use IO::File;
use Digest::MD5;
use WebService::Dropbox;
use Win32::FileOp;

sub
{
	my $bin = shift();
	my $ext = shift();
	local *B = \$Tuyoipyazo::MainFrame::B;
	local *C = \$Tuyoipyazo::MainFrame::C;
	local *D = \$Tuyoipyazo::MainFrame::D;

	$B->{WebService::Dropbox} = WebService::Dropbox->new({qw(key tnsj6up3vp05ixa secret zvk3zhmc6oqjv3t)});
	$B->{WebService::Dropbox}->access_token($C->{Dropbox}->{ACCESS_TOKEN} // "a");
	$B->{WebService::Dropbox}->access_secret($C->{Dropbox}->{ACCESS_TOKEN_SECRET} // "a");

	if($B->{WebService::Dropbox}->account_info()){
		$B->{WebService::Dropbox}->root("sandbox");
		$B->{WebService::Dropbox}->files_put(my $fn = sprintf("%d_%s.%s",time(),Digest::MD5::md5_hex(${$bin}),$ext),${$bin});
		return(0,($B->{WebService::Dropbox}->shares($fn) // {})->{url});
	}else{
		#Win32::FileOp::ShellExecute($B->{WebService::Dropbox}->login());
		Win32::API->new(qw(SHELL32 ShellExecute NPPPPN N))->Call(0,"open",$B->{WebService::Dropbox}->login(),0,0,0);
		if(Wx::MessageBox(
			"",
			__PACKAGE__,
			Wx::wxOK|Wx::wxCANCEL,
			undef,
		) == Wx::wxOK && $B->{WebService::Dropbox}->auth()){
			$C->{Dropbox}->{ACCESS_TOKEN} = $B->{WebService::Dropbox}->access_token();
			$C->{Dropbox}->{ACCESS_TOKEN_SECRET} = $B->{WebService::Dropbox}->access_secret();
			$C->write("Tuyoipyazo.conf");
			return(1);
		}else{
			Wx::MessageBox(
				$B->{WebService::Dropbox}->error(),
				__PACKAGE__,
				Wx::wxOK|Wx::wxICON_EXCLAMATION,
				undef,
			);
			return(0);
		}
	}
}
