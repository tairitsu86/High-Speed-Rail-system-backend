package server;

import java.util.Vector;

public class HSRServerManager {
	public static HSRServerManager hsrsm = new HSRServerManager();
	private static Vector<Integer> ports = new Vector<Integer>();
	public static void main(String [] args) {
		System.out.println(HSRSystemCommand.valueOf("ConnectTest"));
	}
	public HSRServerWindow createServer(String serverName,int port,int timeout){
		if(!ports.contains(port)) {
			ports.add(port);
			return HSRServerWindow.createServer(serverName,port,timeout);
		}else {
			return null;
		}
	}
	public void removePort(int port) {
		ports.removeElement(port);
	}
	public static void ConnectMessageRecord(String RequestType,String Request,String Response,String ClientIP) {
		SQLServerDriverConnect ssdc = new SQLServerDriverConnect();
		ssdc.connect(String.format("EXEC CMRecorder '%s','%s','%s','%s'", RequestType.replaceAll("'", "''"),Request.replaceAll("'", "''"),Response.replaceAll("'", "''"),ClientIP.replaceAll("/", "")));
	}
}
