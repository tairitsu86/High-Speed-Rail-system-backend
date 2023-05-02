package server;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.util.concurrent.BlockingQueue;

public class HSRServer extends Thread {
	
	public static boolean connectMessageEnable = true; 
	private Socket server;
	private String response,request,clientIP,requestType;
	private HSRSystemCommand cmd;
	BlockingQueue<String> connectMessage = HSRServerManagerGUI.connectMessage;
	private HSRServer(Socket server){
		this.server = server;
	}

	public static HSRServer createServer(Socket server){
		return new HSRServer(server);
	}

	@Override
	public void run() {
		try{
			System.out.println("Server address:" + server.getRemoteSocketAddress());
			DataInputStream in = new DataInputStream(server.getInputStream());
			request = in.readUTF();
			cmd = HSRSystemCommand.HSRSC.getCommandType(request);
			requestType = cmd.getName();
			response = cmd.commandExecute();
			clientIP = server.getRemoteSocketAddress().toString();
			System.out.println(response);
			DataOutputStream out = new DataOutputStream(server.getOutputStream());
			if(response==null)
				response = "Error!!!";
			if(connectMessageEnable)
				connectMessageWriter();
			out.writeUTF(response);
			server.close();
	    }catch(SocketTimeoutException s){
	           System.out.println("Socket timed out!");
	    }catch(SocketException e){
	        	System.out.printf("%s been closed!",this.getName());
	    } catch (IOException e) {
				e.printStackTrace();
		}
	}
	
	public void connectMessageWriter() {
		try {
			connectMessage.put(String.format("%s:a client send commend to server[%s]\n", HSRServerManagerGUI.getNow(),getName()));
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		HSRServerManager.ConnectMessageRecord(requestType,request,response,clientIP);
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
