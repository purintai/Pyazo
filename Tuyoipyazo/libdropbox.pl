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
		$B->{WebService::Dropbox}->shares($fn);
		print $B->{WebService::Dropbox}->shares($fn)->{url}."\n";
	return;
	}else{
		Win32::FileOp::ShellExecute($B->{WebService::Dropbox}->login());
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
