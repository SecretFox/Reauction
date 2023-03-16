import com.Components.InventoryItemList.MCLItemInventoryItem;
import com.Components.MultiColumnList.HeaderButton;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.TradepostSearchResultData;
import com.Utils.Archive;
import com.GameInterface.Tradepost;
import mx.utils.Delegate;
import com.Utils.LDBFormat;

class com.fox.Reauction.Reauction {
	private var SavedData:Object;
	private var m_clearButton:MovieClip;
	private static var EXPIRATION_DAYS:String = LDBFormat.LDBGetText("MiscGUI", "expirationDays");
	private var BuyView:MovieClip;

	public static function main(swfRoot:MovieClip):Void {
		var ReAuc:Reauction = new Reauction(swfRoot)
		swfRoot.onLoad = function() { ReAuc.onLoad(); }
		swfRoot.OnUnload = function() { ReAuc.OnUnload();}
		swfRoot.OnModuleActivated = function(config:Archive) { ReAuc.OnModuleActivated(config);}
		swfRoot.OnModuleDeactivated = function() { return ReAuc.OnModuleDeactivated(); }
	}

	public function Reauction(swfRoot: MovieClip) {
	}

	public function onLoad() {
		Tradepost.SignalSearchResult.Connect(GetSearchData, this);
		Tradepost.SignalSearchResult.Connect(SlotResultsReceived, this);
	}

	public function OnModuleActivated(config: Archive) {
		SavedData = new Object();

		SavedData["MainOnly"] = Boolean(config.FindEntry("MainOnly", true));
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
		HookWindow();
	}

	public function OnModuleDeactivated() : Archive {
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

	public function OnUnload() {
		Tradepost.SignalSearchResult.Disconnect(GetSearchData, this);
		Tradepost.SignalSearchResult.Disconnect(SlotResultsReceived, this);
	}

	private function SlotResultsReceived() {
		if (BuyView) {
			BuyView.m_SearchHelptext._visible = false;
			var itemsArray:Array = new Array();
			BuyView.UnSelectRows();
			BuyView.m_ResultsList.RemoveAllItems();

			var resultsCount:Number = Tradepost.m_SearchResults.length;
			var showUsableOnly:Boolean = BuyView.m_UsableItemsOnlyCheckBox.selected;

			for (var i:Number = 0; i < resultsCount; ++i ) {
				var result:TradepostSearchResultData = Tradepost.m_SearchResults[i];
				BuyView.m_CurrentSearchResult = result.m_SearchResultId;

				if (!showUsableOnly || result.m_Item.m_CanUse) {
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
					itemsArray.push(item);
				}
			}
			BuyView.m_ResultsList.AddItems(itemsArray);
			if (SavedData["SortColumn"]) {
				BuyView.m_ResultsList.SetSortColumn(SavedData["SortColumn"]);
				BuyView.m_ResultsList.SetSortDirection(SavedData["SortDirection"]);
				BuyView.m_ResultsList.Resort();
			}
			BuyView.m_ResultsList.SetScrollBar(BuyView.m_ScrollBar);
			BuyView.Layout();
			if (BuyView.m_SellItemPromptWindow._visible){
				Selection.setFocus(BuyView.m_SellItemPromptWindow.m_ItemCounter.m_TextInput.textField);
			}
		}
	}
	
	private function Search(){
		BuyView._Search();
		BuyView.m_SearchButton.disabled = false;
	}
	
	private function KillFocus(newFocus)
	{
		if (BuyView.m_ItemTypeDropdownMenu && newFocus == null)
		{
			Selection.setFocus(BuyView.m_ItemTypeDropdownMenu);
			Selection.setFocus(null);
		}
	}

	private function HookWindow() {
		BuyView = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
		if (!BuyView._visible || !BuyView.m_SearchButton._x || !BuyView.m_SellItemPromptWindow["SlotCashAmountChanged"] ||
			(_root["tradepostutil\\tradepostutil"] && !BuyView.u_clearText))
		{
			setTimeout(Delegate.create(this, HookWindow), 50);
			return
		}
		var saveMode = BuyView.m_ResultsFooter.attachMovie("CheckboxDark", "m_saveMode",  BuyView.m_ResultsFooter.getNextHighestDepth());
		saveMode.autoSize = "left";
		saveMode.label = "Save all";
		saveMode.selected = !SavedData.MainOnly;
		saveMode.addEventListener("select", this, "ModeChanged");
		BuyView.m_SearchField.textField.onKillFocus = Delegate.create(this, KillFocus);
		saveMode._x = BuyView.m_ResultsFooter._width - BuyView.m_UsableItemsOnlyCheckBox._width - saveMode._width + 50;
		saveMode._y = BuyView.m_UsableItemsOnlyCheckBox._y;
		DrawButton();
		//Patron text is stealing clicks
		BuyView.m_MemberText._width = "350";
		
		//Extend search to enable search button
		BuyView._Search = BuyView.Search;
		BuyView.Search = Delegate.create(this, Search);
		
		//Each price column
		BuyView.m_SellItemPromptWindow.m_ItemCounter.SignalValueChanged.Connect(SlotCashAmountChanged, this);
		BuyView.m_ResultsList.AddColumn(MCLItemInventoryItem.INVENTORY_ITEM_COLUMN_SELL_PRICE, "Each", 123, 0);
		BuyView.m_ResultsList.SetSize(758, 390);
		
		Tradepost.SignalSearchResult.Disconnect(BuyView.SlotResultsReceived);

		// sort results
		if (SavedData["SortColumn"]) {
			for (var i in BuyView.m_ResultsList.m_HeaderView.m_HeaderButtons)
			{
				var Header:HeaderButton = BuyView.m_ResultsList.m_HeaderView.m_HeaderButtons[i];
				if (Header.GetId() == SavedData["SortColumn"])
				{
					Header.SetShowArrow(true);
					Header.SetSortDirection(SavedData["SortDirection"]);
					if (SavedData["SortDirection"] != 0)
					{
						Header["m_SortArrow"]._rotation = -180;
					}
					break;
				}
			}
			BuyView.m_ResultsList.SetSortColumn(SavedData["SortColumn"]);
			BuyView.m_ResultsList.SetSortDirection(SavedData["SortDirection"]);
		}
		BuyView.m_ResultsList.SignalSortClicked.Connect(SlotSortChanged, this);
	}
	
	private function ModeChanged() {
		SavedData.MainOnly = !SavedData.MainOnly;
		DrawButton();
	}

	private function DrawButton() {
		if (!SavedData.MainOnly) {
			var BuyView = _root.tradepost.m_Window.m_Content.m_ViewsContainer.m_BuyView;
			m_clearButton = BuyView.attachMovie("ChromeButtonGray", "m_clearButton", BuyView.getNextHighestDepth());
			m_clearButton.textField.text = LDBFormat.LDBGetText(100, 49866466).toUpperCase();
			m_clearButton._x = BuyView.m_SearchButton._x;
			m_clearButton._y = BuyView.m_SearchButton._y-25;
			m_clearButton._width = BuyView.m_SearchButton._width;
			m_clearButton._visible = true;
			m_clearButton.addEventListener("click", this, "ClearSearchData");
		} else {
			m_clearButton.removeMovieClip();
		}
		PopulateFields();
	}

	private function PopulateFields() {
		var type:MovieClip = BuyView.m_ItemTypeDropdownMenu;
		if (type.selectedIndex != SavedData.type) {
			type.selectedIndex = SavedData.type;
			type.dispatchEvent({type:"select"});
		}

		var subtype = BuyView.m_SubTypeDropdownMenu;
		if (!SavedData.MainOnly) {
			// there's small delay on populating subtypes
			setTimeout(Delegate.create(this, function() {
				if ( subtype.selectedIndex != this.SavedData.subtype)
				{
					subtype.selectedIndex = this.SavedData.subtype;
					subtype.dispatchEvent({type:"select"});
				}
			}), 50);

			var rarity = BuyView.m_RarityDropdownMenu;
			var minstack = BuyView.m_MinStacksField;
			var maxstack = BuyView.m_MaxStacksField;
			var searchField = BuyView.m_SearchField;
			var exact = BuyView.m_UseExactNameCheckBox;
			var useable = BuyView.m_UsableItemsOnlyCheckBox;

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

	private function SlotSortChanged() {
		SavedData["SortColumn"] = BuyView.m_ResultsList.GetSortColumn();
		SavedData["SortDirection"] = BuyView.m_ResultsList.GetSortDirection();
	}

	private function SlotCashAmountChanged(newValue) {
		if (BuyView.m_SellItemSlot) {
			var inv:Inventory = new Inventory(BuyView.m_SellItemInventory);
			var item:InventoryItem = inv.GetItemAt(BuyView.m_SellItemSlot);
			if (item.m_StackSize > 1) {
				var commissionFee:Number = (newValue == 0) ? 0 : Math.round(newValue * (1.0 - com.GameInterface.Utils.GetGameTweak("TradePost_SalesCommission")));
				BuyView.m_SellItemPromptWindow.m_WhenSoldPremiumCash.m_Label.text += " (" + Math.round(newValue / item.m_StackSize) + " ea)";
			}
		}
	}

	private function ClearSearchData() {
		var type = BuyView.m_ItemTypeDropdownMenu;
		var subtype = BuyView.m_SubTypeDropdownMenu;
		var rarity = BuyView.m_RarityDropdownMenu;

		var minstack = BuyView.m_MinStacksField;
		var maxstack = BuyView.m_MaxStacksField;
		var searchField = BuyView.m_SearchField;

		var exact = BuyView.m_UseExactNameCheckBox;
		var useable = BuyView.m_UsableItemsOnlyCheckBox;

		SavedData["type"] = type.selectedIndex;
		subtype.selectedIndex = SavedData["subtype"] = 0;
		rarity.selectedIndex = SavedData["rarity"] = 0;
		minstack.text = SavedData["minStack"] = "0";
		maxstack.text = SavedData["maxStack"] = "9999999";
		SavedData["keywords"] = "";
		exact.selected = SavedData["exact"] = false;
		useable.selected = SavedData["useable"] = false;
		searchField.text = SavedData.keywords;
	}

	private function GetSearchData() {
		if (BuyView) {
			var type = BuyView.m_ItemTypeDropdownMenu;
			var subtype = BuyView.m_SubTypeDropdownMenu;
			var rarity = BuyView.m_RarityDropdownMenu;

			var minstack = BuyView.m_MinStacksField;
			var maxstack = BuyView.m_MaxStacksField;
			var keywords = BuyView.m_SearchField;

			var exact = BuyView.m_UseExactNameCheckBox;
			var useable = BuyView.m_UsableItemsOnlyCheckBox;

			SavedData["type"] = type.selectedIndex;
			SavedData["subtype"] = subtype.selectedIndex;
			SavedData["rarity"] = rarity.selectedIndex;
			SavedData["minStack"] = minstack.text;
			SavedData["maxStack"] = maxstack.text;
			SavedData["keywords"] = keywords.text;
			SavedData["exact"] = exact.selected;
			SavedData["useable"] = useable.selected;
		}
	}

}