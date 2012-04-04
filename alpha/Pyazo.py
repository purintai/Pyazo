import sys
import os
import time
import webbrowser
import ConfigParser
import wx
import ctypes
import ImageGrab
import dropbox

def getResolution(): # 解像度を取得
	x = ctypes.windll.user32.GetSystemMetrics(0)
	y = ctypes.windll.user32.GetSystemMetrics(1)
	return x,y

def up2Dropbox(now_time):
        # 初期設定値
        default = {"access_key" : "",
                   "access_key_secret" : ""
                   }
        # Dropbox APIに鍵喰わせる
        APP_KEY = 'tnsj6up3vp05ixa'
        APP_SECRET = 'zvk3zhmc6oqjv3t'
        ACCESS_TYPE = 'app_folder'
        sess = dropbox.session.DropboxSession(APP_KEY, APP_SECRET, ACCESS_TYPE)
        configfile = "Pyazo.cfg"
        config = ConfigParser.SafeConfigParser(default)

        try: # 設定ファイル読み込んでみる
                f = open(configfile, "r")
                config.readfp(f)
                f.close()
                print "Info: configfile loaded"
                sess.set_token(config.get("DEFAULT","access_key"),config.get("DEFAULT","access_key_secret"))
        except IOError:
                try: # 設定ファイルが読めない場合、作成を試みる
                        f = open(configfile, "w")
                except IOError:
                        # 書けなかったら終了
                        print >> sys.stderr, "Error: cannot write file:", configfile
                        sys.exit(1)
                # 初期設定を書き込む
                config.write(f)
                f.close()
                print "Info: new configfile created"

        client = dropbox.client.DropboxClient(sess)

        try: # ちゃんと認証できてるか確かめる
                client.account_info()
        except: # できてなかったら認証しにいく
                while 1:
                        request_token = sess.obtain_request_token()
                        webbrowser.open(sess.build_authorize_url(request_token))
                        print "Please visit this website and press the 'Allow' button, then hit 'Enter' here."
                        raw_input()
                        try:
                                access_token = sess.obtain_access_token(request_token)
                                config.set("DEFAULT","access_key",access_token.key)
                                config.set("DEFAULT","access_key_secret",access_token.secret)
                                print "Auth successful."
                                break
                        except:
                                print "Auth failed. please try again."
                                continue

                f = open(configfile, "w")
                config.write(f)
                f.close()
                print "Config wrote."

        f = open("temp.png","rb")
        client.put_file(now_time+".png",f)
        f.close()
        print webbrowser.open(client.share(now_time+".png")["url"])
        print "all done."

class myFrame(wx.Frame):
	def __init__(self, parent, title):
		wx.Frame.__init__(self, parent, title=title,style = wx.NO_BORDER | wx.FRAME_SHAPED)
		self.SetClientSize(getResolution()) # ウィンドウサイズを設定
		self.SetTransparent(1) # ウィンドウ透明度 0にするとイベント受け付けない
		self.SetCursor(wx.StockCursor(wx.CURSOR_CROSS)) # 十字カーソルにする

		# イベント定義
		self.Bind(wx.EVT_LEFT_DOWN, self.LeftDown)
		self.Bind(wx.EVT_LEFT_UP, self.LeftUp)
		self.Bind(wx.EVT_RIGHT_UP, self.RightUp)

	def LeftDown(self, event): # 左マウスボタンを押した時
		self.Cpoint = event.GetPosition()

	def LeftUp(self, event): # 左マウスボタンを放した時
                self.SetTransparent(0)
		x, y = event.GetPosition()
		x2, y2 = self.Cpoint
		now_time = str(int(time.time())) # 時間ゲットしてunixtimeに変換
		img = ImageGrab.grab((min(x,x2),min(y,y2),max(x,x2),max(y,y2)))
		img.save("temp.png")
		up2Dropbox(now_time)
		self.Close()
		
	def RightUp(self, event): # 右マウスボタンを放した時(キャンセル終了用)
		self.Close()

app = wx.App(False)
myFrame(None, "Pyazo").Show()
app.MainLoop()
