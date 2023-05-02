package server;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.util.ArrayList;

public class HSRSClient {
    public static void main(String [] args) {
    	ddos();
//    	String json = "{\r\n"
//    			+ "  \"CommandType\": \"Book\",\r\n"
//    			+ "  \"ID\": \"A111111111\",\r\n"
//    			+ "  \"OneWayReturn\": \"True\",\r\n"
//    			+ "  \"StartDate\": \"2000/11/3\",\r\n"
//    			+ "  \"StartStation\": \"南港\",\r\n"
//    			+ "  \"ArriveStation\": \"台北\",\r\n"
//    			+ "  \"Tickets\": \"65,0,0,0,0\",\r\n"
//    			+ "  \"Order\": \"F809\",\r\n"
//    			+ "  \"Type\": \"商務車廂\",\r\n"
//    			+ "  \"Prefer\": \"無偏好\"\r\n"
//    			+ "}\r\n"
//    			+ "";
//        System.out.println(SendJsonToServer(json));
    }
    public static String SendJsonToServer(String json) {
    	String serverIP = "140.136.151.128",returnJSON = "{\"State\":\"False\"}";
    	int port = 10001;
        try {
            System.out.println("Connect to server:" + serverIP + " ,port:" + port);
            long t1 = System.nanoTime();
            Socket client = new Socket(serverIP, port);
            OutputStream outToServer = client.getOutputStream();
            DataOutputStream out = new DataOutputStream(outToServer);
            //send json
            out.writeUTF(json);
            InputStream inFromServer = client.getInputStream();
            DataInputStream in = new DataInputStream(inFromServer);
            //get json
            returnJSON = in.readUTF();
            client.close();
            long t2 = System.nanoTime();
            //print execute time
//            System.out.println((t2-t1)/1_000_000_000.0+"sec");
        }catch(IOException e) {
            e.printStackTrace();
        }
        return returnJSON;
    }
    private static void ddos() {
    	ArrayList<Thread> al = new ArrayList<Thread>();
    	String json = "{\r\n"
    			+ "  \"CommandType\": \"Book\",\r\n"
    			+ "  \"ID\": \"A111111%03d\",\r\n"
    			+ "  \"OneWayReturn\": \"True\",\r\n"
    			+ "  \"StartDate\": \"2000/11/3\",\r\n"
    			+ "  \"StartStation\": \"南港\",\r\n"
    			+ "  \"ArriveStation\": \"台北\",\r\n"
    			+ "  \"Tickets\": \"1,0,0,0,0\",\r\n"
    			+ "  \"Order\": \"F809\",\r\n"
    			+ "  \"Type\": \"商務車廂\",\r\n"
    			+ "  \"Prefer\": \"無偏好\"\r\n"
    			+ "}\r\n"
    			+ "";
    	for(int i=0;i<1000;i++) {
    		final int id = i;
    		al.add(new Thread() {
	    			@Override
		    		public void run() {
	    				SendJsonToServer(String.format(json,id));
	    			}
    			});
    	}
    	System.out.println("Start ddos!");
    	long t1 = System.nanoTime();
    	for(int i=0;i<1000;i++) {
    		al.get(i).start();
    	}
    	long t2 = System.nanoTime();
    	System.out.println((t2-t1)/1_000_000_000.0+"sec");
    }

}
