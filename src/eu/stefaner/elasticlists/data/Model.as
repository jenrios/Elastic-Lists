/*
   
Copyright 2010, Moritz Stefaner

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
   
 */

package eu.stefaner.elasticlists.data {		import eu.stefaner.elasticlists.App;

	import org.osflash.thunderbolt.Logger;

	import flash.events.EventDispatcher;	import flash.utils.Dictionary;

	/**	 *  Model	 *		 *	manages ContentItem and Facet collections, filter states etc	 *		 * 	@langversion ActionScript 3	 *	@playerversion Flash 9.0.0	 *	 *	@author moritz@stefaner.eu	 */	public class Model extends EventDispatcher {

		public var app : App;		public var facets : Array = [];		public var facetValuesForContentItem : Dictionary = new Dictionary(true);		public var activeFilters : Dictionary = new Dictionary(true);		public var allContentItems : Array = [];		public var filteredContentItems : Array = [];		protected var allContentItemsForFacetValue : Dictionary = new Dictionary(true);		protected var contentItemsById : Dictionary = new Dictionary(true);		public static var ANDselectionWithinFacets : Boolean = true;

		public function Model(a : App) {			app = a;		};

		public function hasActiveFilters() : Boolean {			return !(filteredContentItems.length == allContentItems.length);		}

		// adds a facet		// REVISIT: could overwrite pre-existing facet with same name in lookup maps!		public function addFacet(f : Facet) : Facet {			facets.push(f);			// prepare lookup map per facet value			for each (var facetValue:FacetValue in f.facetValues) {				allContentItemsForFacetValue[facetValue] = [];			}			return f;		}

		public function createFacet(name : String, type : String = "") : Facet {			if(getFacetByName(name)) {				throw new Error("Cannot add facet, because it is already present: " + name);				return;			}						switch(type) {			/*
				case  :				return addFacet(new HierarchicalFacet(this, name));												case "date" :				return addFacet(new DateFacet(name));				 */	 				case Facet.GEO :					return addFacet(new GeoFacet(this, name));				default:					return addFacet(new Facet(this, name));			}			 			 			return addFacet(new Facet(this, name));		};

		// returns a facet by name		public function getFacetByName(name : String) : Facet {			for each(var facet:Facet in facets) {				if (facet.name == name) {					return facet;				}			}			return null;						}

		public function updateGlobalFacetStats() : void {			for each (var facet:Facet in facets) {				facet.calcGlobalStats();			}		}

		public function updateLocalFacetStats() : void {			for each (var facet:Facet in facets) {				facet.calcLocalStats();			}		}

		//---------------------------------------		// CONTENTITEMS		//---------------------------------------		public function createContentItem(id : String) : ContentItem {			return getContentItemById(id) || addContentItem(app.createContentItem(id));		};

		public function getContentItemById(id : String) : ContentItem {			return contentItemsById[id];		}

		// REVISIT: lookup should be moved to Facet object?		public function getAllContentItemsForFacetValue(f : FacetValue) : Array {			if(allContentItemsForFacetValue[f] == undefined) {				allContentItemsForFacetValue[f] = [];			}			return allContentItemsForFacetValue[f];		}

		public function getNumContentItemsForFacetValue(f : FacetValue) : int {			return getAllContentItemsForFacetValue(f).length;		}

		// adds a content items		private function addContentItem(c : ContentItem) : ContentItem {			if(!contentItemsById[c.id]) {				allContentItems.push(c);				contentItemsById[c.id] = c;				facetValuesForContentItem[c] = new Array();				return c;				} else {				// TODO: adopt new values?				return contentItemsById[c.id]; 			}		};

		// short cut function with a lengthy name		// will create facet value if necessary!		public function assignFacetValueToContentItemByName(contentItemId : String, facetName : String, facetValueName : String) : void {			var contentItem : ContentItem = getContentItemById(contentItemId);			var facet : Facet = getFacetByName(facetName);			var facetValue : FacetValue = facet.getFacetValueByName(facetValueName);			if(facetValueName == null) {				throw new Error("facetValueName cannot be null");			}			if(facetValue == null) {				facetValue = facet.createFacetValue(facetValueName);			}			assignFacetValueToContentItem(facetValue, contentItem);		}		

		// REVISIT: lookup should be moved to Facet object		public function assignFacetValueToContentItem(f : FacetValue, c : ContentItem) : void {			if(f == null || c == null) {				throw new Error("*** NULL VALUE: assignFacetValueToContentItem " + f + " " + c);			}									if(allContentItemsForFacetValue[f] == undefined) {				allContentItemsForFacetValue[f] = [];			}						allContentItemsForFacetValue[f].push(c);			facetValuesForContentItem[c].push(f);						/*			// check if facetValue is hierarchical and has a parent			var ff : HierarchicalFacetValue = f as HierarchicalFacetValue;			if(ff != null && ff.hasParent()) {				assignFacetValueToContentItem(ff.parentFacetValue, c);			}			 * 			 */		};	

		//---------------------------------------		// FILTERS		//---------------------------------------		public function resetFilters() : void {			for each(var facet:Facet in facets) {				for each(var facetValue:FacetValue in facet.facetValues) {					facetValue.selected = false;				}			}			applyFilters();		};

		// gets selected filters from facets, stores them in activeFilters dict		public function updateActiveFilters() : void {			activeFilters = new Dictionary();			for each(var facet:Facet in facets) {				var filter : Array = facet.getSelectedFacetValues();				if(filter.length) {					activeFilters[facet] = filter;				}			}		};

		// updates ContentItem states, filteredContentItems based on filters		public function applyFilters() : void {			trace("Model.applyFilters");						updateActiveFilters();			var c : ContentItem;			if(activeFilters.length == 0) {				// All items visible				// that was easy				filteredContentItems = allContentItems;				for each(c in allContentItems) {					c.filteredOut = false;				}			} else {				// filter out non-matching items								filteredContentItems = [];												for each(c in allContentItems) {					if(contentItemMatchesFilters(c, activeFilters)) {						c.filteredOut = false;						filteredContentItems.push(c);					} else {						c.filteredOut = true;					}				}			}			Logger.info("Model. onFilteredContentItemsChanged: " + filteredContentItems.length + " results");		};

		// tests if a contentitem matches all filters in passed filters dictionary at least once per type 		// (AND conjunction of OR queries within one facet)		protected function contentItemMatchesFilters(c : ContentItem, filters : Dictionary) : Boolean {						var facetValues : Array = facetValuesForContentItem[c];			var f2 : FacetValue;			for each(var a:Array in filters) {				// for all facets				var found : Boolean = false;				for each(var filter:FacetValue in a) {					if(!ANDselectionWithinFacets) {					// for all values in facet filter						for each(f2 in facetValues) {							// check if present in facetValues of contentitem							if(filter == f2) {								found = true;								break;							}						}						if(found) {							break;						}					} else {						found = false;						// for all values in facet filter						for each(f2 in facetValues) {							// check if present in facetValues of contentitem							if(filter == f2) {								found = true;								break;							}						}						if(!found) {							break;						}					}				}				// we found a non-matching filter -> abort								if(!found) {					return false;				}			}				// all good			return true;		}

		public function getTotalNumContentItemsForFacetValue(f : FacetValue) : int {			return getAllContentItemsForFacetValue(f).length;		}

		public function getFilteredNumContentItemsForFacetValue(f : FacetValue) : int {			// get all ContentItems			var contentItems : Array = getAllContentItemsForFacetValue(f);			// count all which are not filtered out			var count : int = 0;			for each (var c:ContentItem in contentItems) {				if(!c.filteredOut) {					count++;				}			}			return count;		}	}}