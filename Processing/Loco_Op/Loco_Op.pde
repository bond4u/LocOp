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
 
private static final int REQUEST_ENABLE_BT = 3;
final String TAG = "MyBt";

ArrayList<BluetoothDevice> devices;
BluetoothAdapter adapter;
//BluetoothDevice dev1;
//BluetoothSocket sock1;

//InputStream ins1;
//OutputStream ous1;

//boolean registered = false;

int f1s;//font1 size
PFont f1;
int f2s;//font2 size
PFont f2;
// BT states:0=no bt
// 1=bt on but scan in progress
// 2=bt on and devices list but no selection
int btState=0;
// loco holds it's state
Loco loco1=null;

//String error;
String cValue;
String pValue;
int fm;// font size multiplier
int speed;
////////////////////////////////////////////
// button class for canvas - drawable and hit-testable
class MyButt {
  int x;
  int y;
  int w;
  int h;
  String t;
  MyButt(int x, int y, int w, int h, String t) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.t = t;
  }
  void draw() {
    fill(255, 0, 0); //red
    rect(x, y, w, h);
    fill(255, 255, 0);//yellow
    text(t, x+49, y+65);
  }
  boolean isHit(int mX, int mY) {
    return (mX > x) && (mX < (x+w)) && (mY > y) && (mY < (y+h));
  }
}
////////////////////////////////////////////////////////
// Locomotive group - bunch of buttons and labels
class Loco {
  BluetoothDevice dev;
  BluetoothSocket sock;
  InputStream ins;
  OutputStream ous;
  String err = null;
  int x;
  int y;
  int w;
  int h;
  int sx2;
  MyButt stop;
  MyButt fwd;
  MyButt bck;
  Loco(BluetoothDevice d, int x, int y) {
    this.dev = d;
    this.x = x;
    this.y = y;
    w = displayWidth-50*2;
    h = 150;
    sx2 = displayWidth/2;
    stop = new MyButt(displayWidth/2-100, y+h+100, 200, 100, "Stop");
    fwd = new MyButt(displayWidth/2+250, y+h+100, 250, 100, "Full fwd");
    bck = new MyButt(displayWidth/2-500, y+h+100, 300, 100, "Full back");
  }
  String getName() {
    return dev.getName();
  }
  void connect() {   
    try {
      sock = dev.createRfcommSocketToServiceRecord(UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"));
    } catch (Exception ex) {
      Log.e(TAG, getName()+".connect.sock.create.exc="+ex);
      err = ex.toString();
    }
    /*
      Method m = device.getClass().getMethod("createRfcommSocket", new Class[] { int.class });     
      socket = (BluetoothSocket) m.invoke(device, 1);             
    */
    Log.i(TAG, getName()+".connect.socket="+sock);
    if (null != sock) {
      try {
        sock.connect();
      } catch (Exception ex) {
        Log.e(TAG, getName()+".connect.sock.connect.exc="+ex);
        err = ex.toString();
      }
      Log.i(TAG, getName()+".connect.isConnected="+sock.isConnected());
      if (null != sock && sock.isConnected()) {
        try {
          ins = sock.getInputStream();
        } catch (Exception ex) {
          Log.e(TAG, getName()+".connect.ins.exc="+ex);
          err = ex.toString();
        }
        Log.i(TAG, getName()+".connect.ins="+ins);
        try {
          ous = sock.getOutputStream();
        } catch (Exception ex) {
          Log.e(TAG, getName()+".connect.ous.exc="+ex);
          err = ex.toString();
        }
        Log.i(TAG, getName()+".connect.ous="+ous);
      } // sock.connected
    } // sock
  }
  void showError()
  {
//    background(255, 0, 0);
    fill(255, 0, 0);
    rect(x, y, w, h);
    fill(255, 255, 0);
    textFont(f2);
    textAlign(CENTER);
//    translate(width / 2, height / 2);
    //rotate(3 * PI / 2);
    text(err, x, y, w, h);
  }
  void showControls(String pVal, String cVal) {
    background(0);
    fill(255);
    // loco name
    text(dev.getName(), 50, y-50);
    // separator line
    line(50, height/2-250, width-100, height/2-250);
    // previous text
    text(pVal, (width/2)-50, (height/2)-150);
    // and current text from locomotive
    text(cVal, (width/2)-50, (height/2)+50);
    // separator line
    line(50, height/2+0, width-100, height/2+0);
    
    // speed slider bg
    stroke(255, 255, 0);
    fill(255, 0, 0);
    rect(x, y, w, h);
    
    // speed text next to slide area
    fill(255, 255, 0);
    text("Speed="+speed, displayWidth/2-50, y-25);
    
    // slider button
    fill(0, 255, 0);
    rect(sx2-40, y+10, 40*2, h-20);
    
    stop.draw();
    fwd.draw();
    bck.draw();
  }
  void draw(String pVal, String cVal) {
    if (null != err) {
      showError();
    } else {
      read();
      showControls(pVal, cVal);
    }
  }
  void read() {
    try {     
      while (null != dev && null != sock && sock.isConnected() &&
          null != ins && ins.available() > 0) {
        char c = (char)ins.read();
        if (c == '\n' || c == '\r') {
          if (cValue != "") {
            pValue = cValue;
          }
          cValue = "";
        } else {
          cValue += c;
        }
        Log.i(TAG, getName()+".read="+c+";"+cValue);
      }
    } catch(Exception ex) {
      Log.e(TAG, getName()+".read.exc="+ex);
//    state = 4;
      err = ex.toString();
    }
  }
  void write(String s) {
    try {
      Log.i(TAG, getName()+".write="+s);
      for (int i= 0; i < s.length(); ++i) {
        char c = s.charAt(i);
        ous.write(c);
      }
      Log.i(TAG, getName()+".write,sent="+s);
    } catch(Exception ex) {
      Log.e(TAG, getName()+".write.exc="+ex);
//      state = 4;
      err = ex.toString();
    }
  }
  boolean isSpeedHit(int mX, int mY) {
    boolean is = mX > x && mX < (x+w) && mY > y && mY < (y+h);
    if (is) {
      int mid = x+(w/2);
      // map from sx..sx+sw (display) range to -255..+255 (locomotive) range
      speed = (int)map((float)mouseX, (float)(x+40), (float)(x+w-40*2), (float)-255, (float)+255);
      sx2 = mX;
      Log.i(TAG, getName()+".isSpeedHit:mid="+mid+",sx2="+sx2+",sp="+speed);
    }
    return is;
  }
  boolean isFfHit(int mX, int mY) {
    boolean is = fwd.isHit(mX, mY);
    if (is) {
      speed = 255;
      sx2 = x+w-40;
      Log.i(TAG, getName()+".isFfHit,sx2="+sx2+",sp="+speed);
    }
    return is;
  }
  boolean isFbHit(int mX, int mY) {
    boolean is = bck.isHit(mX, mY);
    if (is) {
      speed = -255;
      sx2 = x+40;
      Log.i(TAG, getName()+".isFbHit,sx2="+sx2+",sp="+speed);
    }
    return is;
  }
  boolean isStopHit(int mX, int mY) {
    boolean is = stop.isHit(mX, mY);
    if (is) {
      speed = 0;
      sx2 = displayWidth/2;
      Log.i(TAG, getName()+".isStopHit,sx2="+sx2+",sp="+speed);
    }
    return is;
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
BroadcastReceiver receiver = new BroadcastReceiver()
{
  public void onReceive(Context context, Intent intent)
  {
    Log.i(TAG, "onReceive.start");
    String action = intent.getAction();
    Log.i(TAG, "onReceive.action="+action);
    if (BluetoothDevice.ACTION_FOUND.equals(action))
    {
      Log.i(TAG, "onReceive.action_found");
      BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
      Log.i(TAG, "onReceive="+device.getName() + "/" + device.getAddress());
      devices.add(device);
    }
    else if (BluetoothAdapter.ACTION_DISCOVERY_STARTED.equals(action))
    {
//          state = 0;
      btState = 1; // BT on, but no devices yet
      Log.i(TAG, "onReceive.discovery.started");
    }
    else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action))
    {
//          state = 1;
      btState = 2; // got devices list
      Log.i(TAG, "onReceive.discovery.finished");
    }
  }
};
 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void setup() {
  Log.i(TAG, "setup.start");
  fullScreen();
  frameRate(25);
  fm=3;
  f1s=20*fm;
  f1 = createFont("Arial",f1s,true);
  f2s=15*fm;
  f2 = createFont("Arial",f2s,true);
  stroke(255);
  cValue="";
  pValue="";
  Log.i(TAG, "setup.end,f1s="+f1s+",f2s="+f2s+",dw="+displayWidth+",dh="+displayHeight);
  speed=0;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void draw() {
  switch(btState)
  {
    case 0:
      welcome();
    case 1:
      listDevices("Searching for devices..", color(255, 0, 0));
      break;
    case 2:
      if (null == loco1) {
        listDevices("Select device..", color(0, 255, 0));
      } else {
        showData();
      }
      break;
/*    case 3:
      connectDevice();
      break;*/
/*    case 4:
      showData();
      break;*/
/*    case 5:
      showError();
      break;*/
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onStart()
{
  super.onStart();
  Log.i(TAG, "onStart");
  adapter = BluetoothAdapter.getDefaultAdapter();
  Log.i(TAG, "onStart.adapter="+adapter);
  if (null != adapter) {
    if (!adapter.isEnabled()) {
      Log.i(TAG, "onStart.requesting.enable.bt");
      Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
      startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
      Log.i(TAG, "onStart.requested.bt");
    } else {
      btState = 1; // BT was already on, devices list should be present
      getDevicesList();
    }
  } // else no adapter - no BT?
  Log.i(TAG, "onStart.done:btState="+btState);
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onStop()
{
  Log.i(TAG, "onStop,btState="+btState);
  /*
  if(registered)
  {
    unregisterReceiver(receiver);
  }
  */
  if(null != loco1 && null != loco1.sock) {
    Log.i(TAG, "onStop.closing.socket");
    try {
      loco1.sock.close();
    } catch(IOException ex) {
      Log.i(TAG, "onStop.socket.close.exc="+ex);
    }
  }
  super.onStop();
  Log.i(TAG, "onStop.done,btState="+btState);
}
/////////////////////////////////////////
// display welcome screen with instructions
void welcome() {
  background(0, 255, 0);
  fill(255, 255, 255);
  textFont(f2);
  textAlign(CENTER);
//  translate(width / 2, height / 2);
  //rotate(3 * PI / 2);
  text("1. Enable bluetooth\n"+
    "2. Pair a Loco\n"+
    "3. Come back here\n"+
    "4. Paired Locos will be shown here\n"+
    "\n\n\n\n\n", displayWidth/2, displayHeight/2);
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void onActivityResult (int requestCode, int resultCode, Intent data)
{
  Log.i(TAG, "onActivityResult,req="+requestCode+",result="+resultCode);
  if (REQUEST_ENABLE_BT == requestCode) {
    if(Activity.RESULT_OK == resultCode) {
      Log.i(TAG, "onActivityResult.enable.bt=RESULT_OK");
      btState = 1; // BT was enabled, scan in progress, i guess
      getDevicesList();
    } else {
      Log.i(TAG, "onActivityResult.enable.bt=RESULT_CANCELED");
      btState = 0;
//    error = "Bluetooth has not been activated\nEnable BT and pair a Loco";
    }
  } else {
    Log.e(TAG, "onActivityResult.unknown.code="+requestCode);
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void mouseReleased()
{
  switch(btState)
  {
    case 0:
      /*
      if(registered)
      {
        adapter.cancelDiscovery();
      }
      */
      break;
    case 1: // fall through
    case 2:
      if (null == loco1) {
        checkSelection();
      } else {
        checkButton();
      }
      break;
/*    case 3:
      checkButton();
      break;*/
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void getDevicesList()
{
  Log.i(TAG, "getDevicesList.start,btState="+btState);
  devices = new ArrayList<BluetoothDevice>();
    /*
    registerReceiver(receiver, new IntentFilter(BluetoothDevice.ACTION_FOUND));
    registerReceiver(receiver, new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_STARTED));
    registerReceiver(receiver, new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED));
    registered = true;
    adapter.startDiscovery();
    */
  Log.i(TAG, "getDevicesList.adapter="+adapter);
  if (null != adapter) {
    for (BluetoothDevice device : adapter.getBondedDevices()) {
      devices.add(device);
    }
    btState = devices.size() > 0 ? 2 : 1; // have something to select
  } else {
    btState = 0; // no adapter - no BT?
  }
  Log.i(TAG, "getDevicesList.devices="+devices.size());
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
        text(device.getName(), 25, pos);
      }
      fill(180,180,255);
      text(device.getAddress(), 25, pos + 20*fm);
      fill(255);
      line(25, pos + 30*fm, 319*2, pos + 30*fm);
    }
  }
}
///////////////////////////////////////////////////////////////////////////////////
void checkSelection()
{
  int selection = (mouseY - (50*fm)) / (55*fm);
  if (selection < devices.size())   
  {     
    BluetoothDevice dev1 = (BluetoothDevice) devices.get(selection);
//    btState = 2;
    loco1 = new Loco(dev1, 50, 300);
    Log.i(TAG, "checkSelection,sel="+selection+",dev="+dev1.getName()+",btState="+btState);
    loco1.connect();
  } 
} 
/////////////////////////////////////////////////////////////////////////////////////////// 
//////////////////////////////////////////////////////////////////////////////
void showData() 
{   
/*  if (null!=dev1 && null==loco1) {
    loco1 = new Loco(dev1.getName(), 50, 300);
  }*/
  if (null != loco1) {
    loco1.draw(pValue, cValue);
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void checkButton()
{
  String send = "";
  if (null != loco1 && loco1.isSpeedHit(mouseX, mouseY)) {
    send = "s";
    if (speed > 0) send += '+';
    send += Integer.valueOf(speed);
    send += '\n';
  }
  if (null != loco1 && loco1.isFfHit(mouseX, mouseY)) {
    send = "s+255\n";
  }
  if (null != loco1 && loco1.isFbHit(mouseX, mouseY)) {
    send = "s-255\n";
  }
  if (null != loco1 && loco1.isStopHit(mouseX, mouseY)) {
    send = "s0\n";
  }
  if (send != "" && null != loco1)
  {
    loco1.write(send);
  }
}
/////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////