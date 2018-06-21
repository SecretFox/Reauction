import com.Components.InventoryItemList.MCLItemInventoryItem;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.TradepostSearchResultData;
import com.Utils.Archive;
import com.GameInterface.Tradepost;
import com.GameInterface.DistributedValue;
import com.Utils.ID32;
import mx.utils.Delegate;
import com.Utils.LDBFormat;

class com.fox.Reauction.Reauction {
	private var SavedData:Object;
	private var TradePostSignal:DistributedValue;
	private var m_clearButton:MovieClip;
	private static var EXPIRATION_DAYS:String = LDBFormat.LDBGetText("MiscGUI", "expirationDays");

	public static function main(swfRoot:MovieClip):Void {
		var ReAuc = new Reauction(swfRoot)
		swfRoot.onLoad = function() { ReAuc.startUp(); }
		swfRoot.OnModuleActivated = function(config:Archive) { ReAuc.LoadConfig(config);}
		swfRoot.OnModuleDeactivated = function() { return ReAuc.SaveConfig(); }
		swfRoot.OnUnload = function() { ReAuc.CleanUp();}
	}
	
	public function Reauction(swfRoot: MovieClip) {
		TradePostSignal = DistributedValue.Create("tradepost_window");
	}

	public function startUp() {
		Tradepost.SignalSearchResult.Connect(GetSearchData, this);
		Tradepost.SignalSearchResult.Connect(SlotResultsReceived, this);
		TradePostSignal.SignalChanged.Connect(TradePostOpened, this);
		setTimeout(Delegate.create(this, TradePostOpened), 1000);
	}

	public function LoadConfig(config: Archive) {
		SavedData = new Object();

		SavedData["MainOnly"] = Boolean(config.FindEntry("MainOnly", false));
		SavedData["SortColumn"] = Number(config.FindEntry("SortColumn",-1));
		SavedData["SortDirection"] = Number(config.FindEntry("SortDirection",0));

		SavedData["type"] = Number(config.FindEntry("type", 0));
		SavedData["subtype"] = Number(config.FindEntry("subtype", 0));
		SavedData["rarity"] = Number(config.FindEntry("rarity", 0));

		SavedData["minStack"] = string(config.FindEntry("minStack", "0"));
		SavedData["maxStack"] = string(config.FindEntry("maxStack", "9999999"));
		SavedData["keywords"] = string(config.FindEntry("keywords", ""));

		SavedData["exact"] = Boolean(config.FindEntry("exact", false));
		SavedData["useable"] = Boolean(config.FindEntry("useable", false));
	}

	public function SaveConfig() : Archive {
		var archive: Archive = new Archive();

		archive.AddEntry("MainOnly", SavedData.MainOnly);
		archive.AddEntry("type", SavedData.type);
		archive.AddEntry("subtype", SavedData.subtype);
		archive.AddEntry("rarity", SavedData.rarity);

		archive.AddEntry("minStack", SavedData.minStack);
		archive.AddEntry("maxStack", SavedData.maxStack);
		archive.AddEntry("keywords", SavedData.keywords);

		archive.AddEntry("exact", SavedData.exact);
		archive.AddEntry("useable", SavedData.useable);
		archive.AddEntry("SortColumn", SavedData.SortColumn);
		archive.AddEntry("SortDirection", SavedData.SortDirection);
		return archive
	}
	
	public function CleanUp() {
		Tradepost.SignalSearchResult.Disconnect(GetSearchData, this);
		TradePostSignal.SignalChanged.Disconnect(TradePostOpened, this);
		Tradepost.SignalSearchResult.Disconnect(SlotResultsReceived, this);
	}

	
	private function TradePostOpened() {
		if (TradePostSignal.GetValue()) {
			var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
			if (!buyview._visible || !buyview.m_SearchButton._x || !buyview.m_SellItemPromptWindow["SlotCashAmountChanged"]) {
				setTimeout(Delegate.create(this, TradePostOpened), 50);
				return
			}
			var saveMode = buyview.m_ResultsFooter.attachMovie("CheckboxDark", "m_saveMode",  buyview.m_ResultsFooter.getNextHighestDepth());
			saveMode.autoSize = "left";
			saveMode.label = "Save all parameters";
			saveMode.selected = false;
			saveMode.selected = !SavedData.MainOnly;
			saveMode.addEventListener("select", this, "ModeChanged");
			saveMode._x = buyview.m_ResultsFooter._width - buyview.m_UsableItemsOnlyCheckBox._width - saveMode._width - 10;
			saveMode._y = buyview.m_ResultsFooter._height / 2 - saveMode._height / 2;
			DrawButton();

			/*
			buyview.splitText = undefined;
			if (!buyview._Search){
				buyview._Search = buyview.Search;
				buyview.Search = function () {
					var txt = this.m_SearchField.text;
					var split = txt.split(" * ");
					if ( split[1]){
						this.splitText = split[1];
						this.m_SearchField.text = split[0];
					}else{
						this.splitText = undefined;
					}
					this._Search();
				}
			}
			*/
			// calculates each price for sell prompt
			buyview.m_SellItemPromptWindow.m_ItemCounter.SignalValueChanged.Connect(SlotCashAmountChanged, this);
			// Adds new column based on repair price
			buyview.m_ResultsList.AddColumn(MCLItemInventoryItem.INVENTORY_ITEM_COLUMN_SELL_PRICE, "Each", 123, 0);
			buyview.m_ResultsList.SetSize(758, 390);
			Tradepost.SignalSearchResult.Disconnect(buyview.SlotResultsReceived);
			if (SavedData["SortColumn"]){
				buyview.m_ResultsList.SetSortColumn(SavedData["SortColumn"]);
				buyview.m_ResultsList.SetSortDirection(SavedData["SortDirection"]);
			}
			buyview.m_ResultsList.SignalSortClicked.Connect(SlotSortChanged, this);
		}
	}
	
	private function SlotResultsReceived(){
		var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
		if(buyview){
			buyview.m_SearchHelptext._visible = false;
			var itemsArray:Array = new Array();
			buyview.UnSelectRows();
			buyview.m_ResultsList.RemoveAllItems();
			
			var resultsCount:Number = Tradepost.m_SearchResults.length;
			var showUsableOnly:Boolean = buyview.m_UsableItemsOnlyCheckBox.selected;
				
			for (var i:Number = 0; i < resultsCount; ++i )
			{
				var result:TradepostSearchResultData = Tradepost.m_SearchResults[i];
				buyview.m_CurrentSearchResult = result.m_SearchResultId;
				
				if (!showUsableOnly || result.m_Item.m_CanUse)
				{
					//trace(result.m_TokenType1);
					result.m_Item.m_TokenCurrencyType1 = result.m_TokenType1;
					result.m_Item.m_TokenCurrencyPrice1 = result.m_TokenType1_Amount;
					result.m_Item.m_TokenCurrencyType2 = result.m_TokenType2;
					result.m_Item.m_TokenCurrencyPrice2 = result.m_TokenType2_Amount;
					result.m_Item.m_TokenCurrencySellPrice1 = Math.round(result.m_Item.m_TokenCurrencyPrice1 / result.m_Item.m_StackSize);
					result.m_Item.m_TokenCurrencySellType1 = result.m_TokenType1;
					result.m_Item.m_TokenCurrencySellPrice2 = Math.round(result.m_Item.m_TokenCurrencyPrice2 / result.m_Item.m_StackSize);
					result.m_Item.m_TokenCurrencyType2 = result.m_TokenType2;

					var item:MCLItemInventoryItem = new MCLItemInventoryItem(result.m_Item, undefined);
					item.SetId( result.m_ItemId );
			
					item.m_Seller = result.m_SellerName;
					item.m_Expires = Math.round(result.m_ExpireDate / 86400) + " " + EXPIRATION_DAYS;
					/*
					if (buyview.splitText){
						var idx = item.m_InventoryItem.m_Name.toLowerCase().lastIndexOf(buyview.splitText.toLowerCase());
						var idx2 = item.m_InventoryItem.m_Name.toLowerCase().indexOf(buyview.m_SearchField.text.toLowerCase());
						if ( idx == -1 && item.m_InventoryItem.m_Name){
							continue
						}else if(idx > idx2+buyview.m_SearchField.text.length){
							itemsArray.push(item);
						}
					}else{
						itemsArray.push(item);
					}
					*/
					itemsArray.push(item);
				}
			}
			buyview.m_ResultsList.AddItems(itemsArray); 
			if (SavedData["SortColumn"]){
				buyview.m_ResultsList.SetSortColumn(SavedData["SortColumn"]);
				buyview.m_ResultsList.SetSortDirection(SavedData["SortDirection"]);
				buyview.m_ResultsList.Resort();
			}
			buyview.m_ResultsList.SetScrollBar(buyview.m_ScrollBar);
			buyview.Layout();
		}
	}

	private function ModeChanged(){
		SavedData.MainOnly = !SavedData.MainOnly;
		DrawButton();
	}
	
	private function DrawButton(){
		if (!SavedData.MainOnly) {
			var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
			m_clearButton = buyview.attachMovie("ChromeButtonGray", "m_clearButton", buyview.getNextHighestDepth());
			m_clearButton.disableFocus = true;
			m_clearButton.textField.text = LDBFormat.LDBGetText(100, 49866466).toUpperCase();
			m_clearButton._x = buyview.m_SearchButton._x;
			m_clearButton._y = buyview.m_SearchButton._y-25;
			m_clearButton._width = buyview.m_SearchButton._width;
			m_clearButton._visible = true;
			m_clearButton.addEventListener("click", this, "ClearSearchData");
		}else{
			m_clearButton.removeMovieClip();
		}
		PopulateFields();
	}
	
	private function PopulateFields(){
		var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
		var type:MovieClip = buyview.m_ItemTypeDropdownMenu;
		if (type.selectedIndex != SavedData.type){
			type.selectedIndex = SavedData.type;
			type.dispatchEvent({type:"select"});
		}

		var subtype = buyview.m_SubTypeDropdownMenu;
		if (!SavedData.MainOnly) {
			// there's 20ms delay on populating subtypes
			setTimeout(Delegate.create(this, function(){
				subtype.selectedIndex = this.SavedData.subtype;
				subtype.dispatchEvent({type:"select"});
			}), 50);

			var rarity = buyview.m_RarityDropdownMenu;
			var minstack = buyview.m_MinStacksField;
			var maxstack = buyview.m_MaxStacksField;
			var searchField = buyview.m_SearchField;
			var exact = buyview.m_UseExactNameCheckBox;
			var useable = buyview.m_UsableItemsOnlyCheckBox;

			rarity.selectedIndex = SavedData.rarity;
			rarity.dispatchEvent({type:"select"});

			minstack.text = SavedData.minStack;
			maxstack.text = SavedData.maxStack;

			searchField.text = SavedData.keywords;
			var textFormat:TextFormat = searchField.textField.getTextFormat();
			textFormat.align = "left";
			searchField.textField.setTextFormat(textFormat);

			exact.selected = SavedData.exact;
			useable.selected = SavedData.useable;
		}
	}

	private function SlotSortChanged(){
		var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
		SavedData["SortColumn"] = buyview.m_ResultsList.GetSortColumn();
		SavedData["SortDirection"] = buyview.m_ResultsList.GetSortDirection();
	}
	
	private function SlotCashAmountChanged(newValue){
		var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
		if (buyview.m_SellItemSlot){
			var inv:Inventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, com.GameInterface.Game.Character.GetClientCharID().GetInstance()))
			var item:InventoryItem = inv.GetItemAt(buyview.m_SellItemSlot);
			if(item.m_StackSize>1){
				var commissionFee:Number = (newValue == 0) ? 0 : Math.round(newValue * (1.0 - com.GameInterface.Utils.GetGameTweak("TradePost_SalesCommission")));
				buyview.m_SellItemPromptWindow.m_WhenSoldPremiumCash.m_Label.text += " (" + Math.round(newValue / item.m_StackSize) + " ea)";
			}
		}
	}

	private function ClearSearchData() {
		var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;

		var type = buyview.m_ItemTypeDropdownMenu;
		var subtype = buyview.m_SubTypeDropdownMenu;
		var rarity = buyview.m_RarityDropdownMenu;

		var minstack = buyview.m_MinStacksField;
		var maxstack = buyview.m_MaxStacksField;
		var searchField = buyview.m_SearchField;

		var exact = buyview.m_UseExactNameCheckBox;
		var useable = buyview.m_UsableItemsOnlyCheckBox;

		SavedData["type"] = type.selectedIndex;
		SavedData["subtype"] = 0;
		SavedData["rarity"] = 0;
		SavedData["minStack"] = "0";
		SavedData["maxStack"] = "9999999";
		SavedData["keywords"] = "";
		SavedData["exact"] = false;
		SavedData["useable"] = false;

		subtype.selectedIndex = SavedData.subtype;
		rarity.selectedIndex = SavedData.rarity;

		minstack.text = SavedData.minStack;
		maxstack.text = SavedData.maxStack;

		searchField.text = SavedData.keywords;

		exact.selected = SavedData.exact;
		useable.selected = SavedData.useable;
	}

	private function GetSearchData() {
		var buyview = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
		if(buyview){
			var type = buyview.m_ItemTypeDropdownMenu;
			var subtype = buyview.m_SubTypeDropdownMenu;
			var rarity = buyview.m_RarityDropdownMenu;
			
			var minstack = buyview.m_MinStacksField;
			var maxstack = buyview.m_MaxStacksField;
			var keywords = buyview.m_SearchField;


			var exact = buyview.m_UseExactNameCheckBox;
			var useable = buyview.m_UsableItemsOnlyCheckBox;

			SavedData["type"] = type.selectedIndex;
			SavedData["subtype"] = subtype.selectedIndex;
			SavedData["rarity"] = rarity.selectedIndex;
			SavedData["minStack"] = minstack.text;
			SavedData["maxStack"] = maxstack.text;
			SavedData["keywords"] = keywords.text;
			SavedData["exact"] = exact.selected;
			SavedData["useable"] = useable.selected;
			/*
			if (buyview.splitText){
				SavedData["keywords"] += " * " + buyview.splitText;
			}
			*/
		}
	}

}