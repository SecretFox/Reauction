import com.Utils.Archive;
import com.GameInterface.Tradepost;
import com.GameInterface.DistributedValue;
import mx.utils.Delegate;
import com.Utils.LDBFormat;

class com.fox.ReAuction.ReAuction{
	private var oldData:Object;
	private var m_tradeWindowSignal:DistributedValue;
	private var m_ClearSearchData:DistributedValue;
	private var TYPE_ALL:String = LDBFormat.LDBGetText("MiscGUI", "TradePost_Class_All");
	private var m_clearButton:MovieClip;
	private var m_Auction_MainOnly:DistributedValue;
	
	public static function main(swfRoot:MovieClip):Void 
	{
		var ReAuc = new ReAuction(swfRoot)
		swfRoot.onLoad = function() { ReAuc.startUp(); }
		swfRoot.OnModuleActivated = function(config:Archive) { ReAuc.LoadConfig(config);}
		swfRoot.OnModuleDeactivated = function() { return ReAuc.SaveConfig(); }
		swfRoot.OnUnload = function() { ReAuc.CleanUp();}
	}
	
    public function ReAuction(swfRoot: MovieClip) 
    {
	}
	
	public function startUp()
	{
		Tradepost.SignalSearchResult.Connect(GetSearchData, this)
		m_tradeWindowSignal = DistributedValue.Create("tradepost_window");
		m_tradeWindowSignal.SignalChanged.Connect(TradePostOpened, this);
		
		m_Auction_MainOnly = DistributedValue.Create("Auction_TypeOnly");
		m_Auction_MainOnly.SignalChanged.Connect(SettingsChanged, this);
	}
	
	private function SettingsChanged()
	{
		oldData["MainOnly"] = m_Auction_MainOnly.GetValue();
	}
	
	public function CleanUp()
	{
		Tradepost.SignalSearchResult.Disconnect(GetSearchData, this);
		m_tradeWindowSignal.SignalChanged.Disconnect(TradePostOpened, this);
		m_clearButton.removeMovieClip();
	}
	
	private function TradePostOpened()
	{
		if (m_tradeWindowSignal.GetValue() == true)
		{
			setTimeout(Delegate.create(this, ChangeFields), 0,0);
		}
	}
	
    private function GetSubtypes(type:String):Array 
    {
        var subtypes:Array = new Array();
        for (var i:Number = 0; i < Tradepost.m_TradepostItemTypes[type].length; ++i )
        {
            var key:String = Tradepost.m_TradepostItemTypes[type][i];
            subtypes.push({label: LDBFormat.LDBGetText(10010, key), idx: key});
        }
        subtypes.sortOn("label");
        return subtypes;
    }
	
	private function ChangeFields(attempt)
	{
		var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
		if (buyview.m_SearchButton._x != 0 && buyview.m_SearchButton._x != undefined){
			
			var type:MovieClip = buyview.m_ItemTypeDropdownMenu;
			type.selectedIndex = oldData.type;
			
			var subtype = buyview.m_SubTypeDropdownMenu;
			var subtypes:Array = new Array();
			subtypes.push({label: TYPE_ALL, idx: TYPE_ALL});
			subtypes = subtypes.concat(GetSubtypes(type.selectedItem.idx));
			subtype.dataProvider = subtypes;
			subtype.rowCount = subtypes.length;
			
			if (!oldData.MainOnly){
				subtype.selectedIndex = oldData.subtype;
				
				var rarity = buyview.m_RarityDropdownMenu;
				var minstack = buyview.m_MinStacksField;
				var maxstack = buyview.m_MaxStacksField;
				var searchField = buyview.m_SearchField;
				var exact = buyview.m_UseExactNameCheckBox;
				var useable = buyview.m_UsableItemsOnlyCheckBox;

				rarity.selectedIndex = oldData.rarity;
				
				minstack.text = oldData.minStack;
				maxstack.text = oldData.maxStack;
				
				searchField.text = oldData.keywords
				var textFormat:TextFormat = searchField.textField.getTextFormat();
				textFormat.align = "left";
				searchField.textField.setTextFormat(textFormat);
				
				exact.selected = oldData.exact;
				useable.selected = oldData.useable;
				
				m_clearButton = buyview.attachMovie("ChromeButtonGray", "m_clearButton", buyview.getNextHighestDepth());
				m_clearButton.disableFocus = true;
				m_clearButton.textField.text = LDBFormat.LDBGetText(100, 49866466).toUpperCase();
				m_clearButton._x = buyview.m_SearchButton._x;
				m_clearButton._y = buyview.m_SearchButton._y-25;
				m_clearButton._width = buyview.m_SearchButton._width;
				m_clearButton._visible = true;
				m_clearButton.onMousePress = Delegate.create(this, ClearSearchData);
			}
		}
		else if (attempt < 10){
			setTimeout(Delegate.create(this, ChangeFields), 50, attempt + 1);
		}
	}
	
	private function ClearSearchData()
	{
		var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
		
		var type = buyview.m_ItemTypeDropdownMenu;
		var subtype = buyview.m_SubTypeDropdownMenu;
		var rarity = buyview.m_RarityDropdownMenu;
		
		var minstack = buyview.m_MinStacksField;
		var maxstack = buyview.m_MaxStacksField;
		var searchField = buyview.m_SearchField;
		
		var exact = buyview.m_UseExactNameCheckBox;
		var useable = buyview.m_UsableItemsOnlyCheckBox;

		oldData["type"] = type.selectedIndex
		oldData["subtype"] = 0;
		oldData["rarity"] = 0;
		oldData["minStack"] = "0";
		oldData["maxStack"] = "9999999";
		oldData["keywords"] = "";
		oldData["exact"] = false;
		oldData["useable"] = false;

		subtype.selectedIndex = oldData.subtype;
		rarity.selectedIndex = oldData.rarity;
		
		minstack.text = oldData.minStack;
		maxstack.text = oldData.maxStack;
		
		searchField.text = oldData.keywords
		var textFormat:TextFormat = searchField.textField.getTextFormat();
		textFormat.align = "left";
		searchField.textField.setTextFormat(textFormat);
		
		exact.selected = oldData.exact;
		useable.selected = oldData.useable;
	}
	
	private function GetSearchData()
	{
		var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
		var type = buyview.m_ItemTypeDropdownMenu;
		var subtype = buyview.m_SubTypeDropdownMenu;
		var rarity = buyview.m_RarityDropdownMenu;

		var minstack = buyview.m_MinStacksField;
		var maxstack = buyview.m_MaxStacksField;
		var keywords = buyview.m_SearchField;
		
		var exact = buyview.m_UseExactNameCheckBox;
		var useable = buyview.m_UsableItemsOnlyCheckBox;
		
		oldData["type"] = type.selectedIndex
		oldData["subtype"] = subtype.selectedIndex
		oldData["rarity"] = rarity.selectedIndex
		oldData["minStack"] = minstack.text
		oldData["maxStack"] = maxstack.text
		oldData["keywords"] = keywords.text
		oldData["exact"] = exact.selected
		oldData["useable"] = useable.selected
	}
	
	public function LoadConfig(config: Archive)
	{
		oldData = new Object();
		
		oldData["MainOnly"] = Boolean(config.FindEntry("MainOnly", false));
		m_Auction_MainOnly.SetValue(oldData["MainOnly"]);
		
		oldData["type"] = Number(config.FindEntry("type", 0));
		oldData["subtype"] = Number(config.FindEntry("subtype", 0));
		oldData["rarity"] = Number(config.FindEntry("rarity", 0));
		
		oldData["minStack"] = string(config.FindEntry("minStack", "0"));
		oldData["maxStack"] = string(config.FindEntry("maxStack", "9999999"));
		oldData["keywords"] = string(config.FindEntry("keywords", ""));
		
		oldData["exact"] = Boolean(config.FindEntry("exact", false));
		oldData["useable"] = Boolean(config.FindEntry("useable", false));
		setTimeout(Delegate.create(this, TradePostOpened), 500);
	}
	
	public function SaveConfig() : Archive
	{
		var archive: Archive = new Archive();	
		
		archive.AddEntry("MainOnly", oldData.MainOnly);
		archive.AddEntry("type", oldData.type);
		archive.AddEntry("subtype", oldData.subtype);
		archive.AddEntry("rarity", oldData.rarity);
		
		archive.AddEntry("minStack", oldData.minStack);
		archive.AddEntry("maxStack", oldData.maxStack);
		archive.AddEntry("keywords", oldData.keywords);
		
		archive.AddEntry("exact", oldData.exact);
		archive.AddEntry("useable", oldData.useable);
		return archive
	}
}