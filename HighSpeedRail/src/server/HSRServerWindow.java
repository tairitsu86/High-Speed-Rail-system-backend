package server;

import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.util.concurrent.BlockingQueue;

public class HSRServerWindow extends Thread {
	
	private ServerSocket serverSocket;
	private boolean isContinue = true;
	private int port;
	private int timeout;
	BlockingQueue<String> connectMessage = HSRServerManagerGUI.connectMessage;
	private HSRServerWindow(String serverName,int port,int timeout){
		this.setName(serverName);
		this.port = port;
		this.timeout = timeout;
		try {
			serverSocket = new ServerSocket(port);
			if(timeout>=0)
				serverSocket.setSoTimeout(timeout);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	public int getPort() {
		return port;
	}
	public int getTimeout() {
		return timeout;
	}
	public static HSRServerWindow createServer(String serverName,int port,int timeout){
		return new HSRServerWindow(serverName,port,timeout);
	}
	
	@Override
	public void run() {
		while(isContinue){
			try{
				Socket server = serverSocket.accept();
				HSRServer.createServer(server).run();
	         }catch(SocketTimeoutException s){
	            System.out.println("Socket timed out!");
	         }catch(SocketException e){
	        	System.out.printf("%s been closed!",this.getName());
	         } catch (IOException e) {
				e.printStackTrace();
			}
		}
	}
	private void close() {
		try {
			serverSocket.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	public void terminate() {
        isContinue = false;
        close();
    }
	public String getIP() {
		try {
			InetAddress addr = InetAddress.getLocalHost();
			return addr.getHostAddress();
		} catch (UnknownHostException e) {
			e.printStackTrace();
		}
		return "Get failed";
	}

}
