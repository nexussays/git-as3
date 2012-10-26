package
{

import flash.events.*;
import flash.filesystem.File;
import flash.ui.Keyboard;

import mx.collections.ArrayList;
import mx.controls.Alert;
import mx.controls.FileSystemTree;
import mx.events.*;

import nexus.vcs.git.*;
import nexus.vcs.git.objects.*;

import spark.components.*;
import spark.events.IndexChangeEvent;

public class GitViewer extends WindowedApplication
{
	//--------------------------------------
	//	CLASS CONSTANTS
	//--------------------------------------
	
	static public const STARTING_PATH:String = "C:/Users/nexus/Development/Projects/Personal/ASRake-git_test-gc";
	//static public const STARTING_PATH:String = "C:/Users/nexus/Development/Projects/Personal/ASRake-git_test";
	
	//static public const STARTING_HASH:String = "";
	static public const STARTING_HASH:String = "bdc999cb9e10627342061a6839b8bbfaea49fa03";
	
	//--------------------------------------
	//	MXML FIELDS
	//--------------------------------------
	
	public var buttonChangeRepo:Button;
	public var repoPath:TextInput;
	
	public var objectSearchField:TextInput;
	//public var commitLog:List;
	public var repoTree:FileSystemTree;
	
	public var objectType:Label;
	public var outputText:RichEditableText;
	
	//--------------------------------------
	//	INSTANCE VARIABLES
	//--------------------------------------
	
	private var m_repo:GitRepository;
	private var m_fileBrowser:File;
	//private var m_commitLogData:ArrayList;
	
	//--------------------------------------
	//	CONSTRUCTOR
	//--------------------------------------
	
	public function GitViewer()
	{
		m_repo = new GitRepository();
		
		this.addEventListener(FlexEvent.CREATION_COMPLETE, this_creationComplete);
	}
	
	private function this_creationComplete(e:FlexEvent):void
	{
		this.removeEventListener(FlexEvent.CREATION_COMPLETE, this_creationComplete);
		
		//m_commitLogData = new ArrayList();
		
		m_fileBrowser = File.userDirectory;
		
		//commitLog.dataProvider = m_commitLogData;
		//commitLog.addEventListener(IndexChangeEvent.CHANGE, commitLog_indexChange);
		
		repoTree.visible = false;
		repoTree.showHidden = true;
		repoTree.showIcons = true;
		repoTree.showExtensions = true;
		repoTree.addEventListener(ListEvent.ITEM_CLICK, repoTree_itemClick);
		
		repoPath.addEventListener(KeyboardEvent.KEY_UP, repoPath_keyUp);
		
		buttonChangeRepo.addEventListener(MouseEvent.CLICK, buttonChangeRepo_click);
		
		objectSearchField.text = STARTING_HASH;
		objectSearchField.addEventListener(KeyboardEvent.KEY_UP, objectSearchField_keyUp);
		
		outputText.focusEnabled = false;
		outputText.addEventListener(KeyboardEvent.KEY_DOWN, outputText_keyDown);
		outputText.addEventListener(KeyboardEvent.KEY_UP, outputText_keyUp);
		
		changeGitRepo(STARTING_PATH, false);
	}
	
	//--------------------------------------
	//	GETTER/SETTERS
	//--------------------------------------
	
	//--------------------------------------
	//	PUBLIC INSTANCE METHODS
	//--------------------------------------
	
	//--------------------------------------
	//	EVENT HANDLERS
	//--------------------------------------
	
	private function alert_close(e:Event):void
	{
		browseForDirectory();
	}
	
	/*
	private function commitLog_indexChange(e:Event):void
	{
		repoTree.selectedIndex = -1;
		showHash(commitLog.selectedItem);
	}
	//*/
	
	private function buttonChangeRepo_click(e:MouseEvent):void
	{
		browseForDirectory();
	}
	
	private function repoTree_itemClick(e:Event):void
	{
		var selectedFile:File = File(repoTree.selectedItem);
		if(!selectedFile.isDirectory)
		{
			updateOutputText(m_repo.debug_readFile(selectedFile.url), selectedFile.url.replace(m_repo.gitDirectory.url + "/", ""));
		}
		//commitLog.selectedItem = -1;
	}
	
	private function fileBrowser_select(e:Event):void
	{
		changeGitRepo(m_fileBrowser.nativePath);
	}
	
	private function objectSearchField_keyUp(e:KeyboardEvent):void
	{
		if(e.keyCode == Keyboard.ENTER)
		{
			repoTree.selectedIndex = -1;
			//commitLog.selectedItem = -1;
			objectSearchField.text = objectSearchField.text.replace(/^\s*|\s*$/g, "");
			showHash(objectSearchField.text);
		}
	}
	
	private function repoPath_keyUp(e:KeyboardEvent):void
	{
		if(e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.NUMPAD_ENTER)
		{
			changeGitRepo(repoPath.text);
		}
	}
	
	private function outputText_keyDown(e:KeyboardEvent):void
	{
		e.preventDefault();
	}
	
	private function outputText_keyUp(e:KeyboardEvent):void
	{
		if( (e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.NUMPAD_ENTER)
			&& outputText.selectionActivePosition != -1
			&& outputText.selectionAnchorPosition != -1
			&& Math.abs(outputText.selectionAnchorPosition - outputText.selectionActivePosition) == 40 )
		{
			var min : int = Math.min(outputText.selectionActivePosition, outputText.selectionAnchorPosition);
			var selection : String = outputText.text.substr(min, 40);
			repoTree.selectedIndex = -1;
			//commitLog.selectedItem = -1;
			showHash(selection);
		}
	}
	
	//--------------------------------------
	//	PRIVATE & PROTECTED INSTANCE METHODS
	//--------------------------------------
	
	private function changeGitRepo(path:String, displayAlert:Boolean=true):void
	{
		if(m_repo.directory != null && m_repo.directory.nativePath == path)
		{
			return;
		}
		
		//if there is an existing repository opened, clear it
		if(m_repo.gitDirectory != null)
		{
			objectSearchField.text = "";
			outputText.text = "";
			objectType.text = "";
			repoTree.visible = false;
		}
		
		if(CONFIG::release)
		{
			try
			{
				m_repo.changeRepository(path);
			}
			catch(e:Error)
			{
				if(displayAlert)
				{
					Alert.show(path + " is not a valid git repository\n\n" + e.message, "Error", Alert.OK, null, alert_close);
				}
				else
				{
					browseForDirectory();
				}
				return;
			}
		}
		else
		{
			m_repo.changeRepository(path);
		}
		
		//m_commitLogData.removeAll();
		
		repoPath.text = m_repo.directory.nativePath;
		
		repoTree.directory = m_repo.gitDirectory;
		repoTree.visible = true;
		
		//fill commit log
		//var vector:Vector.<GitCommit> = m_gitManager.commitLog();
		//for(var x:int = vector.length - 1; x >= 0; --x)
		//{
			//m_commitLogData.addItem(vector[x].hash);
		//}
	}
	
	private function showHash(hash:String):void
	{
		try
		{
			updateOutputText(m_repo.getObject(hash));
		}
		catch(e:Error)
		{
			updateOutputText(e.getStackTrace());
		}
	}
	
	private function updateOutputText(object:Object, typeOverride:String=null):void
	{
		objectType.text = "";
		if(object is AbstractGitObject)
		{
			objectType.text = AbstractGitObject(object).hash;
			
			var pack:GitPack = m_repo.getPackForObject(AbstractGitObject(object).hash);
			if(pack != null)
			{
				objectType.text += " *" + pack.name;
			}
		}
		
		outputText.selectRange( -1, -1);
		outputText.text = object + "";
		
		if(typeOverride != null)
		{
			objectType.text = typeOverride;
		}
	}
	
	private function browseForDirectory():void
	{
		if(m_fileBrowser != null)
		{
			m_fileBrowser.removeEventListener(Event.SELECT, fileBrowser_select);
		}
		
		if(m_repo.directory != null)
		{
			m_fileBrowser = m_repo.directory.clone();
		}
		m_fileBrowser.addEventListener(Event.SELECT, fileBrowser_select);
		m_fileBrowser.browseForDirectory("Select a git repository");
	}
}

}