package Tuyoipyazo::MainFrame::Dropbox;
use 5.10.0;
use WebService::Dropbox;
use Win32::FileOp;

sub
{
	$B->{WebService::Dropbox} = WebService::Dropbox->new({qw(key tnsj6up3vp05ixa secret zvk3zhmc6oqjv3t)});
	$B->{WebService::Dropbox}->access_token($C->{Dropbox}->{ACCESS_TOKEN} // "a");
	$B->{WebService::Dropbox}->access_secret($C->{Dropbox}->{ACCESS_TOKEN_SECRET} // "a");

	if($B->{WebService::Dropbox}->account_info()){
	}else{
		Win32::FileOp::ShellExecute($B->{WebService::Dropbox}->login());
		if(Wx::MessageBox(
			"",
			__PACKAGE__,
			Wx::wxOK|Wx::wxCANCEL,
			undef,
		) != Wx::wxOK){
		}
	}
}
