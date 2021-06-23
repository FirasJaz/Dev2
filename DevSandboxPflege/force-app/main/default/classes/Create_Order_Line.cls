/*
 * **************************************************************************************************************************
 * // Created 18.04.2019 von AD
 * // Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
 * // Nordkanalstr. 58
 * // 20097 Hamburg
 * // Tel.: 04023882986
 * // Fax.: 04023882989
 * // Email: kontakt@klosesrockepartner.de
 * //
 * //****************************************************************************************************************************
 * //
 * // Parameter:
 * //
 * //
 * //****************************************************************************************************************************
 * //
 * // Description:
 * //
 * //****************************************************************************************************************************
 * // Changes:
 * ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 */

public with sharing class Create_Order_Line {

	// initialize an order line
	public static Order_Line__c newOrderLine(Order__c order, Product__c product, String curabox) {
		Order_Line__c line = new Order_Line__c();
		line.Order__c = order.Id;
		line.Product__c = product.Id;
		line.Gen_Menge_Stk_Mon__c = getQuantity(curabox, product.Product_Group__r.Name);
		line.Price__c = product.Price__c * line.Gen_Menge_Stk_Mon__c;
		line.Lieferstatus__c = 'noch nicht beliefert';
		return line;
	}

	//
	public static List<Order_Line__c> createOrderLines(Order__c order,
													   String curabox,
													   List<Product_List> pList,
													   String glove1,
													   Integer quantity1,
													   String glove2,
													   Integer quantity2,
													   Product_List spruehkopf,
													   Product_List pumpaufsatz) {
		List<Order_Line__c> orderLineList = new List<Order_Line__c>();
		orderLineList.addAll(createLinesForGloves(order, glove1, quantity1, glove2, quantity2));
		if (!Curabox_Helper.isCB6Flexibel(curabox)) {
			List<Id> productGroupList = Product_List.getProductGroupIds(Product_List.getProductGroupList(curabox));
			if (productGroupList != null && productGroupList.size() > 0) {
				if (curabox != 'KUWV') {
					List<Product__c> productList = Product_List.getProductList(curabox);
					orderLineList.addAll(setOrderLines(order, curabox, productList));
					if (spruehkopf.menge > 0) {
						orderLineList.add(initCB6Line(spruehkopf, order));
					}
					if (pumpaufsatz.menge > 0) {
						orderLineList.add(initCB6Line(pumpaufsatz, order));
					}
				}
				else {
					orderLineList.addAll(createLinesForCB6(pList, order));
				}
			}
		} else {
			pList.add(spruehkopf);
			pList.add(pumpaufsatz);
			orderLineList.addAll(createLinesForCB6(pList, order));
		}
		System.debug('#####################' + orderLineList);
		return orderLineList;
	}
	// Curabox flow
	public static List<Order_Line__c> createOrderLines(Order__c order,
													   String curabox,
													   List<Product_List> pList,
													   String glove1,
													   Integer quantity1,
													   String glove2,
													   Integer quantity2,
													   Product_List spruehkopf) {
		List<Order_Line__c> orderLineList = new List<Order_Line__c>();
		orderLineList.addAll(createLinesForGloves(order, glove1, quantity1, glove2, quantity2));
		if (!Curabox_Helper.isCB6Flexibel(curabox)) {
			List<Id> productGroupList = Product_List.getProductGroupIds(Product_List.getProductGroupList(curabox));
			if (productGroupList != null && productGroupList.size() > 0) {
				if (curabox != 'KUWV') {
					List<Product__c> productList = Product_List.getProductList(curabox);
					orderLineList.addAll(setOrderLines(order, curabox, productList));
					if (spruehkopf.menge > 0) {
						orderLineList.add(initCB6Line(spruehkopf, order));
					} else {
						orderLineList.addAll(createLinesForCB6(pList, order));
					}
				}
			}
		} else {
			pList.add(spruehkopf);
			orderLineList.addAll(createLinesForCB6(pList, order));
		}
		return orderLineList;
	}

	// help method
	public static List<Order_Line__c> setOrderLines(Order__c order, String curabox, List<Product__c> productList) {
		List<Order_Line__c> orderLineList = new List<Order_Line__c>();
		if (productList != null && productList.size() > 0) {
			for (Product__c product : productList) {
				if (product.Product_Group__r.Name != 'Einmalhandschuhe') {
					orderLineList.add(newOrderLine(order, product, curabox));
				}
			}
		}
		return orderLineList;
	}

	// get the quantity of product that containts a curabox
	public static Decimal getQuantity(String curabox, String productGroup) {
		Decimal menge = 0;
		List<Curabox_Product_Group__c> productGroupList = new List<Curabox_Product_Group__c>();
		try {
			productGroupList = [Select Id, default_number__c from Curabox_Product_Group__c Where Curabox__r.Name =: curabox AND Product_Group__r.Name=:productGroup limit 1];
		} catch (Exception e) {
			System.debug(e);
		}
		return productGroupList[0].default_number__c;
	}

	// create all order lines for CB6
	public static List<Order_Line__c> createLinesForCB6(List<Product_List> pList, Order__c order) {
		List<Order_Line__c> lines = new List<Order_Line__c>();
		if (pList != null && pList.size() > 0) {
			for (Product_List product : pList) {
				if (product.menge > 0) {
					lines.add(initCB6Line(product, order));
				}
			}
		}
		return lines;
	}

	// initialize an order line for CB6
	public static Order_Line__c initCB6Line(Product_List product, Order__c order) {
		Order_Line__c line = new Order_Line__c();
		line.Order__c = order.Id;
		line.Product__c = Product_List.getProductByName(product.name).Id;
		line.Gen_Menge_Stk_Mon__c = product.menge;
		line.Price__c = product.price * product.menge;
		line.Lieferstatus__c = 'noch nicht beliefert';
		return line;
	}

	//
	public static List<Order_Line__c> createLinesForGloves(Order__c order,
														   String glove1,
														   Integer quantity1,
														   String glove2,
														   Integer quantity2) {
		List<Order_Line__c> lines = new List<Order_Line__c>();
		if (glove1 != null && !String.isEmpty(glove1)) {
			if (quantity1 > 0) {
				lines.add(initGloveLine(order, glove1, quantity1));
			}
		}
		if (glove2 != null && !String.isEmpty(glove2)) {
			if (quantity2 > 0) {
				lines.add(initGloveLine(order, glove2, quantity2));
			}
		}
		return lines;
	}

	// initialize an order line for a glove
	public static Order_Line__c initGloveLine(Order__c order, String glove, Integer quantity) {
		Order_Line__c line = new Order_Line__c();
		Product__c product = Product_List.getProductByName(glove);
		line.Order__c = order.Id;
		line.Product__c = product.Id;
		line.Gen_Menge_Stk_Mon__c = Decimal.valueOf(quantity);
		line.Price__c = product.Price__c * quantity;
		line.Lieferstatus__c = 'noch nicht beliefert';
		return line;
	}

	// get all order line Ids that contains a order.
	public static List<Id> getOrderLinesIds(String orderId) {
		List<Order_Line__c> lineList = new List<Order_Line__c>();
		List<Id> idList = new List<Id>();
		try {
			lineList = [Select Id, Name from Order_Line__c where Order__c =:orderId];
		} catch (Exception e) {
			System.debug(e);
		}
		if (lineList.size() > 0) {
			for (Order_Line__c line : lineList) {
				idList.add(line.Id);
			}
		}
		return idList;
	}

}