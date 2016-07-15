import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;
import java.util.UUID;
//import java.util.ArrayList;
//import java.io.IOException;
//import java.io.InputStream;
//import java.io.OutputStream;
//import java.lang.reflect.Method;
 
private static final int REQUEST_ENABLE_BT = 3;
final String TAG = "MyBt";
ArrayList<BluetoothDevice> devices;
BluetoothAdapter adapter;
BluetoothDevice device;
BluetoothSocket socket;
InputStream ins;
OutputStream ons;
boolean registered = false;
int f1s;//font1 size
PFont f1;
int f2s;//font2 size
PFont f2;
int state;
String error;
String cValue;
String pValue;
int fm;// font size multiplier
int speed;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
BroadcastReceiver receiver = new BroadcastReceiver()
{
    public void onReceive(Context context, Intent intent)
    {
        Log.i(TAG,"onReceive.start");
        String action = intent.getAction();
        Log.i(TAG,"onReceive.action="+action);
        if (BluetoothDevice.ACTION_FOUND.equals(action))
        {
          Log.i(TAG,"onReceive.action_found");
          BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
          Log.i(TAG,"onReceive="+device.getName() + "/" + device.getAddress());
          devices.add(device);
        }
        else if (BluetoothAdapter.ACTION_DISCOVERY_STARTED.equals(action))
        {
          state = 0;
          Log.i(TAG,"onReceive.discovery.started");
        }
        else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action))
        {
          state = 1;
          Log.i(TAG,"onReceive.discovery.finished");
        }
    }
};
 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void setup() {
  fullScreen();
  //size(320,480);
  frameRate(25);
  fm=3;
  f1s=20*fm;
  f1 = createFont("Arial",f1s,true);
  f2s=15*fm;
  f2 = createFont("Arial",f2s,true);
  stroke(255);
  cValue="";
  pValue="";
  Log.i(TAG,"setup.end,f1s="+f1s+",f2s="+f2s+",dw="+displayWidth+",dh="+displayHeight);
  speed=0;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void draw() {
  switch(state)
  {
    case 0:
      listDevices("Searching for devices", color(255, 0, 0));
      break;
    case 1:
      listDevices("Select device", color(0, 255, 0));
      break;
    case 2:
      connectDevice();
      break;
    case 3:
      showData();
      break;
    case 4:
      showError();
      break;
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onStart()
{
  super.onStart();
  Log.i(TAG,"onStart");
  adapter = BluetoothAdapter.getDefaultAdapter();
  Log.i(TAG,"onStart.adapter="+adapter);
  if (adapter != null)
  {
    if (!adapter.isEnabled())
    {
      Log.i(TAG,"onStart.requesting.enable.bt");
        Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
        startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
    }
    else
    {
      start2();
    }
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onStop()
{
  Log.i(TAG,"onStop");
  /*
  if(registered)
  {
    unregisterReceiver(receiver);
  }
  */
  if(socket != null)
  {
    Log.i(TAG,"onStop.closing.socket");
    try
    {
      socket.close();
    }
    catch(IOException ex)
    {
      Log.i(TAG,"onStop.socket.close="+ex);
    }
  }
  super.onStop();
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onActivityResult (int requestCode, int resultCode, Intent data)
{
  Log.i(TAG,"onActivityResult,req="+requestCode+",result="+resultCode);
  if(resultCode == Activity.RESULT_OK)
  {
    Log.i(TAG,"onActivityResult=RESULT_OK");
    start2();
  }
  else
  {
    Log.i(TAG,"onActivityResult=RESULT_CANCELED");
    state = 4;
    error = "Bluetooth has not been activated";
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void mouseReleased()
{
  switch(state)
  {
    case 0:
      /*
      if(registered)
      {
        adapter.cancelDiscovery();
      }
      */
      break;
    case 1:
      checkSelection();
      break;
    case 3:
      checkButton();
      break;
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void start2()
{
  Log.i(TAG,"start2.start");
    devices = new ArrayList<BluetoothDevice>();
    /*
    registerReceiver(receiver, new IntentFilter(BluetoothDevice.ACTION_FOUND));
    registerReceiver(receiver, new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_STARTED));
    registerReceiver(receiver, new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED));
    registered = true;
    adapter.startDiscovery();
    */
  Log.i(TAG,"start2.adapter="+adapter);
    if (null!=adapter)
    {
      for (BluetoothDevice device : adapter.getBondedDevices())
      {
        devices.add(device);
      }
      state = 1;
    }
  Log.i(TAG,"start2.devices="+devices.size());
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void listDevices(String text, color c)
{
  background(0);
  textFont(f1);
  fill(c);
  text(text, 25, f1s);
  if(devices != null)
  {
    for(int idx = 0; idx < devices.size(); idx++)
    {
      BluetoothDevice device = (BluetoothDevice) devices.get(idx);
      fill(255,255,0);
      int pos = (fm*50) + (idx * (55*fm));
      if(device.getName() != null)
      {
        text(device.getName(),25, pos);
      }
      fill(180,180,255);
      text(device.getAddress(),25, pos + 20*fm);
      fill(255);
      line(25, pos + 30*fm, 319, pos + 30*fm);
    }
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void checkSelection()
{
  int selection = (mouseY - (50*fm)) / (55*fm);
  if(selection < devices.size())   
  {     
    device = (BluetoothDevice) devices.get(selection);     
    Log.i(TAG,"checkSelection="+device.getName());     
    state = 2;   
  } 
} 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
void connectDevice() 
{   
  try   
  {     
    socket = device.createRfcommSocketToServiceRecord(UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"));
    /*     
      Method m = device.getClass().getMethod("createRfcommSocket", new Class[] { int.class });     
      socket = (BluetoothSocket) m.invoke(device, 1);             
    */
    Log.i(TAG,"connectDevice.socket="+socket);
    socket.connect();
    ins = socket.getInputStream();
    Log.i(TAG,"connectDevice.ins="+ins);
    ons = socket.getOutputStream();
    Log.i(TAG,"connectDevice.ons="+ons);
    state = 3;   
  }   
  catch(Exception ex)   
  {
    Log.e(TAG,"connectDevice="+ex);
    state = 4;     
    error = ex.toString();     
  } 
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class MyButt {
  int x;
  int y;
  int w;
  int h;
  String t;
  MyButt(int x, int y, int w, int h, String t) {
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
    this.t=t;
  }
  void draw() {
    fill(255,0,0); //red
    rect(x,y,w,h);
    fill(255,255,0);//yellow
    text(t,x+49,y+65);
  }
  boolean isHit(int mX, int mY) {
    return (mX > x && mX < (x+w) && mY > y && mY < (y+h));
  }
}
int sx=-1;//slide
int sy=-1;
int sw=-1;
int sh=-1;
int sx2=-1;//slider
//int sx3=-1;//stop
//int sy3=-1;
//int sw3=-1;
//int sh3=-1;
MyButt stop=null;
int sx4=-1;//fwd
int sy4=-1;
int sw4=-1;
int sh4=-1;
int sx5=-1;//back
int sy5=-1;
int sw5=-1;
int sh5=-1;
void showData() 
{   
  try
  {     
    while(ins.available() > 0)
    {
      char c = (char)ins.read();
      if (c==10 || c==13) {
        if (cValue!="") {
         pValue=cValue;
        }
        cValue = "";
      } else {
        cValue += c;
      }
      Log.i(TAG,"showData="+c+";"+cValue);
    }
  }
  catch(Exception ex)
  {
    Log.e(TAG,"showData="+ex);
    state = 4;
    error = ex.toString();
  }
  background(0);
  fill(255);
  // previous text
  text(pValue, (width/2)-50, (height/2)-100);
  // and current text from locomotive
  text(cValue, (width/2)-50, (height/2)+100);
  // speed slider
  stroke(255, 255, 0);
  fill(255, 0, 0);
  if (sx==-1) {
    sx=50;
    sy=300;
    sw=displayWidth-50*2;
    sh=150;
  }
  rect(sx, sy, sw, sh);
  // speed text next to slide area
  fill(255, 255, 0);
  text("Speed="+speed, displayWidth/2-50, sy-25);
  // slider button
  fill(0,255,0);
  if (sx2==-1) {
    sx2=displayWidth/2;
  }
  rect(sx2-40,sy+10,40*2,sh-20);
  // stop button next to slider
//  fill(255,0,0);
//  if (sx3==-1) {
  if (null==stop) {
//    sx3=displayWidth/2-100;
//    sy3=sy+sh+100;
//    sw3=200;
//    sh3=100;
    stop = new MyButt(displayWidth/2-100,sy+sh+100,200,100,"Stop");
  }
//  rect(sx3,sy3,sw3,sh3);
//  fill(255,255,0);
//  text("Stop",sx3+49,sy3+65);
  stop.draw();
  // "full forward" button
  fill(255,0,0);
  if (sx4==-1) {
    sx4=displayWidth/2+250;
    sy4=sy+sh+100;
    sw4=250;
    sh4=100;
  }
  rect(sx4,sy4,sw4,sh4);
  fill(255,255,0);
  text("Full fwd",sx4+48,sy4+65);
  // "full backward" button
  fill(255,0,0);
  if (sx5==-1) {
    sx5=displayWidth/2-500;
    sy5=sy+sh+100;
    sw5=300;
    sh5=100;
  }
  rect(sx5,sy5,sw5,sh5);
  fill(255,255,0);
  text("Full back",sx5+48,sy5+65);
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void checkButton()
{
  String send="";
  if(sx!=-1 && mouseX > sx && mouseX < (sx+sw) && mouseY > sy && mouseY < (sy+sh))
  {
    int mid=sx+(sw/2);
    // map from sx..sx+sw (display) range to -255..+255 (locomotive) range
    speed=(int)map((float)mouseX,(float)(sx+40),(float)(sx+sw-40*2),(float)-255,(float)+255);
    sx2=mouseX;
    Log.i(TAG,"checkButton:mid="+mid+",sx2="+sx2+",sp="+speed);
    send="s";
    if (speed>0) send+='+';
    send+=Integer.valueOf(speed);
    send+='\n';
  }
  if (sx4!=-1 && mouseX > sx4 && mouseY < (sx4+sw4) && mouseY > sy4 && mouseY < (sy4+sh4))
  {
    speed = 255;
    sx2 = sx+sw-40;
    Log.i(TAG,"checkButton:ff,sx2="+sx2+",sp="+speed);
    send="s+255\n";
  }
  if (sx5!=-1 && mouseX > sx5 && mouseX < (sx5+sw5) && mouseY > sy5 && mouseY < (sy5+sh5))
  {
    speed = -255;
    sx2 = sx+40;
    Log.i(TAG,"checkButton:fb,sx2="+sx2+",sp="+speed);
    send = "s-255\n";
  }
  if (null!=stop && stop.isHit(mouseX,mouseY))
//  if (sx3!=-1 && mouseX > sx3 && mouseX < (sx3+sw3) && mouseY > sy3 && mouseY < (sy3+sh3))
  {
    speed=0;
    sx2=displayWidth/2;
    send="s0\n";
  }
  if (send!="")
  {
    try
    {
      Log.i(TAG,"checkButton.sending.speed");
      for (int i= 0; i < send.length(); ++i) {
        char c = send.charAt(i);
        ons.write(c);
      }
    }
    catch(Exception ex)
    {
      Log.e(TAG,"checkButton="+ex);
      state = 4;
      error = ex.toString();
    }
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void showError()
{
  background(255, 0, 0);
  fill(255, 255, 0);
  textFont(f2);
  textAlign(CENTER);
  translate(width / 2, height / 2);
  rotate(3 * PI / 2);
  text(error, 0, 0);
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////