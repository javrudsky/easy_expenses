//
//  RootView.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 11/09/2026.
//

import SwiftUI

struct RootView: View {
    //@StateObject private var viewModel: TransactionsViewModel
    
    let componentFactory: ComponentFactory
    
    init(componentFactory: ComponentFactory) {
        //_viewModel = StateObject(wrappedValue: di.makeTransactionsViewModel())
        self.componentFactory = componentFactory
    }
    
    var body: some View {
        NavigationStack {
            TransactionsView<TransactionsViewModel>(viewModel: componentFactory.createTransactionsViewModel())
        }
    }
}
