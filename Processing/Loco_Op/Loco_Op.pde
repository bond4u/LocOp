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

int f1s;//font1 size
PFont f1;
int f2s;//font2 size
PFont f2;
// BT states:0=no bt
// 1=bt on but scan in progress
// 2=bt on and devices list
// sub-states: null==loco1 -> no selection, null!=loco1 -> loco selected
int btState = 0;
// loco holds it's state
Loco loco1 = null;
Loco loco2 = null;
int fm;// font size multiplier
int lm=700; // loco control size
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
    fill(255, 0, 0); //red rect
    rect(x, y, w, h);
    fill(255, 255, 0); // yellow text
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
  BluetoothSocket sock = null;
  InputStream ins = null;
  OutputStream ous = null;
  String err = null;
  int x;
  int y;
  int w;
  int h;
  int sx2;
  MyButt stop;
  MyButt fwd;
  MyButt bck;
  MyButt close;
  String pVal = ""; // previously read string/line
  String cVal = ""; // currently being read string/line
  int speed = 0;
  Loco(BluetoothDevice d, int x, int y) {
    this.dev = d;
    this.x = x;
    this.y = y;
    w = displayWidth-50*2;
    h = 150;
    sx2 = displayWidth/2; // selection in the middle
    stop = new MyButt(displayWidth/2-100, y+h+100, 200, 100, "Stop");
    fwd = new MyButt(displayWidth/2+250, y+h+100, 250, 100, "Full fwd");
    bck = new MyButt(displayWidth/2-500, y+h+100, 300, 100, "Full back");
    close = new MyButt(displayWidth-200, y-150, 150, 100, "Close");
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
    fill(255, 0, 0); // rec rect
    rect(x, y, w, h);
    fill(255, 255, 0); // yellow text
    textFont(f2);
    textAlign(CENTER);
    text(err, x, y, w, h);
    //close.draw();
  }
  void showControls(/*String pVal, String cVal*/) {
    //background(0);
    fill(255); // white text
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
    stroke(255, 255, 0); // yellow lines
    fill(255, 0, 0); // red rect
    rect(x, y, w, h);
    
    // speed text next to slide area
    fill(255, 255, 0); // yellow text
    text("Speed="+speed, displayWidth/2-50, y-25);
    
    // slider button
    fill(0, 255, 0); // green rect
    rect(sx2-40, y+10, 40*2, h-20);
    
    stop.draw();
    fwd.draw();
    bck.draw();
    //close.draw();
  }
  void render(/*String pVal, String cVal*/) {
    if (null != err) {
      showError();
    } else {
      read();
      showControls(/*pVal, cVal*/);
    }
    close.draw(); // always visible
  }
  void read() {
    try {
      while (null != dev && null != sock && sock.isConnected() &&
          null != ins && ins.available() > 0) {
        char c = (char)ins.read();
        if (c == '\n' || c == '\r') {
          if (cVal != "") {
            pVal = cVal;
          }
          cVal = "";
        } else {
          cVal += c;
        }
        Log.i(TAG, getName()+".read="+c+";"+cVal);
      }
    } catch(Exception ex) {
      Log.e(TAG, getName()+".read.exc="+ex);
      err = ex.toString();
    }
  }
  void write(String s) {
    if (null != sock && sock.isConnected() && null != ous) {
      try {
        Log.i(TAG, getName()+".write="+s);
        for (int i= 0; i < s.length(); ++i) {
          char c = s.charAt(i);
          ous.write(c);
        }
        ous.flush();
        Log.i(TAG, getName()+".write,sent="+s);
      } catch(Exception ex) {
        Log.e(TAG, getName()+".write.exc="+ex);
        err = ex.toString();
      }
    } // else d/c
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
  void checkButtons(int mX, int mY) {
    if (null == err) {
      String send = "";
      if (isSpeedHit(mX, mY)) {
        send = "s";
        if (speed > 0)
          send += '+';
        send += Integer.valueOf(speed);
        send += '\n';
      }
      if (isFfHit(mX, mY)) {
        send = "s+255\n";
      }
      if (isFbHit(mX, mY)) {
        send = "s-255\n";
      }
      if (isStopHit(mX, mY)) {
        send = "s0\n";
      }
      if (send != "")
      {
        write(send);
      }
    } // if no err
    if (close.isHit(mX, mY)) {
      if (null != sock && sock.isConnected()) {
        try {
          sock.close();
        } catch (Exception ex) {
          Log.e(TAG, "checkButtons.close.sock.close.ex="+ex);
        }
      }
      sock = null;
      loco1 = null; // TODO
    } // if close
  } // checkButtons
} // Loco
///////////////////////////////////////////////////////////////////////////////
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
      btState = 1; // BT on, but no devices yet
      Log.i(TAG, "onReceive.discovery.started");
    }
    else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action))
    {
      btState = 2; // got devices list
      Log.i(TAG, "onReceive.discovery.finished");
    }
  }
};
 
///////////////////////////////////////////////////////////////////////////
void setup() {
  Log.i(TAG, "setup.start");
  fullScreen();
  frameRate(25);
  fm=3;
  f1s=20*fm;
  f1 = createFont("Arial",f1s,true);
  f2s=15*fm;
  f2 = createFont("Arial",f2s,true);
  stroke(255); // white lines
  fill(255); // white text color
  background(0); // black background
  //cValue="";
  //pValue="";
  Log.i(TAG, "setup.end,f1s="+f1s+",f2s="+f2s+",dw="+displayWidth+",dh="+displayHeight);
  //speed=0;
}
/////////////////////////////////////////////////////////////////////////////
void draw() {
  background(0); // clear bg to black
  switch(btState)
  {
    case 0:
      welcome();
    case 1:
      listDevices("Searching for devices..", color(255, 0, 0), 0);
      break;
    case 2:
      if (null == loco1) {
        listDevices("Select device..", color(0, 255, 0), 0);
      } else {
        loco1.render();
      }
      if (null == loco2) {
        listDevices("Select device..", color(0, 255, 0), 1);
      } else {
        loco2.render();
      }
      break;
  }
}
/////////////////////////////////////////////////////////////////////////////
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
//////////////////////////////////////////////////////////////////////////
void onStop()
{
  Log.i(TAG, "onStop,btState="+btState);
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
/////////////////////////////////////////////////////////////
// display welcome screen with instructions
void welcome() {
  //background(0, 255, 0);
  //fill(255);//, 255, 255); // white text
  textFont(f2);
  textAlign(CENTER);
  text("1. Enable bluetooth\n"+
    "2. Pair a Loco\n"+
    "3. Come back here\n"+
    "4. Paired Locos will be shown here\n"+
    "\n\n\n\n\n", displayWidth/2, displayHeight/2);
}
///////////////////////////////////////////////////////////////////////////
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
    }
  } else {
    Log.e(TAG, "onActivityResult.unknown.code="+requestCode);
  }
}
/////////////////////////////////////////////////////////////////////////////
void mouseReleased()
{
  switch(btState)
  {
    case 0:
      // do nothing
      break;
    case 1: // fall through
    case 2:
      if (null == loco1) { // TODO intermediate states?
        checkSelection(0);
      } else {
        loco1.checkButtons(mouseX, mouseY);
      }
      if (null == loco2) {
        checkSelection(1);
      } else {
        loco2.checkButtons(mouseX, mouseY);
      }
      break;
  }
}
/////////////////////////////////////////////////////////////////////////////
void getDevicesList()
{
  Log.i(TAG, "getDevicesList.start,btState="+btState);
  devices = new ArrayList<BluetoothDevice>();
  Log.i(TAG, "getDevicesList.adapter="+adapter);
  if (null != adapter) {
    for (BluetoothDevice device : adapter.getBondedDevices()) {
      devices.add(device);
    }
    btState = devices.size() > 0 ? 2 : 1; // have something to select
  } else {
    btState = 0; // no adapter - no BT?
  }
  Log.i(TAG, "getDevicesList.devices="+devices.size()+",dw="+displayWidth+",dh="+displayHeight);
}
/////////////////////////////////////////////////////////////////////////////
void listDevices(String text, color c, int li) // li=loco index
{
  //background(0);
  textFont(f1);
  fill(c); // green? text
  textAlign(LEFT);
  int pos = f1s + (li*lm);
  //Log.i(TAG, "listDevices,li="+li+",f1s="+f1s+",pos="+pos);
  text(text, 25, pos);
  if (null != devices) {
    for (int idx = 0; idx < devices.size(); idx++) {
      BluetoothDevice device = (BluetoothDevice) devices.get(idx);
      fill(255,255,0); // yellow text
      pos = (fm*50) + (idx * (55*fm)) + (li*lm);
      if (null != device.getName()) {
        text(device.getName(), 25, pos); // TODO exclude already connected device
      }
      fill(180,180,255); // gray text
      int pos2 = pos + 20*fm;
      text(device.getAddress(), 25, pos2);
      fill(255); // white text
      int pos3 = pos + 30*fm;
      line(25, pos + 30*fm, 319*2, pos3);
      //Log.i(TAG, "listDevices,fm="+fm+",idx="+idx+",pos="+pos+",pos2="+pos2+",pos3="+pos3);
    } // for
  } // if devices
} // listDevices
//////////////////////////////////////////////////////////////////////////////
void checkSelection(int li) // li=loco index
{
  int sel = (mouseY - (li*lm) - (50*fm)) / (55*fm);
  Log.i(TAG, "checkSelection,mY="+mouseY+",li="+li+",sel="+sel);
  if (0 <= sel && devices.size() > sel)
  {     
    BluetoothDevice dev1 = (BluetoothDevice) devices.get(sel);
    Log.i(TAG, "checkSelection,dev="+dev1.getName()+",btState="+btState);
    if (0 == li) {
      loco1 = new Loco(dev1, 50, 300);
    } else if (1 == li) {
      loco2 = new Loco(dev1, 50, lm); // TODO loco control size
    } // else?
    if (0 == li) {
      loco1.connect();
    } else if (1 == li) {
      loco2.connect();
    } // else?
  }
} 
////////////////////////////////////////////////////////////////////////////// 