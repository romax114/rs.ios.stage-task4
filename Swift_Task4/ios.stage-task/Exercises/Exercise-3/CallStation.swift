import Foundation

final class CallStation {
    var allUsers = [User]()
    var callList = [Call]()
}

extension CallStation: Station {
    func users() -> [User] {
        allUsers
    }
    
    func add(user: User) {
        guard !allUsers.contains(user) else {
            return
        }
        allUsers.append(user)
    }
    
    func remove(user: User) {
        if allUsers.contains(user) {
            allUsers.remove(at: allUsers.firstIndex(of: user)!)
            self.remove(user: user)
        }
    }
    
    func execute(action: CallAction) -> CallID? {
        
        func addToCallList(from: User, to: User, callStatus: CallStatus) -> CallID {
            let call = Call(id: UUID(), incomingUser: from, outgoingUser: to, status: callStatus)
            
            callList.append(call)
            
            return call.id
        }
        
        func changeStatus(call: Call, index: Int, newStatus: CallStatus) -> CallID? {
            let changedCall = Call(id: call.id, incomingUser: call.incomingUser, outgoingUser: call.outgoingUser, status: newStatus)
            callList.remove(at: index)
            callList.insert(changedCall, at: index)
            
            if newStatus == .ended(reason: .error) {
                return nil
            }
            return call.id
        }
        
        switch action {
        case .start(let user1, let user2):
            
            guard allUsers.contains(user1) else {
                return nil
            }
            guard allUsers.contains(user2) else {
                return addToCallList(from: user1, to: user2, callStatus: .ended(reason: .error))
            }
            
            for call in callList{
                if ((call.outgoingUser.id == user2.id || call.incomingUser.id == user2.id) && call.status == .talk) {
                    return addToCallList(from: user1, to: user2, callStatus: .ended(reason: .userBusy))
                }
            }
            
            return addToCallList(from: user1, to: user2, callStatus: .calling)
            
        case .answer(let user2):
            for (index, call) in callList.enumerated() {
                if (call.outgoingUser.id == user2.id && call.status == .calling) {
                    if allUsers.contains(user2) {
                        return changeStatus(call: call, index: index, newStatus: .talk)
                    } else {
                        return changeStatus(call: call, index: index, newStatus: .ended(reason: .error))
                    }
                }
            }
            return nil
            
        case .end(let user):
            for (index, call) in callList.enumerated() {
                if ((call.outgoingUser.id == user.id || call.incomingUser.id == user.id) &&
                        call.status == .talk) {
                    return changeStatus(call: call, index: index, newStatus: .ended(reason: .end))
                }
                if (call.outgoingUser.id == user.id && call.status == .calling) {
                    return changeStatus(call: call, index: index, newStatus: .ended(reason: .cancel))
                }
            }
            return nil
        }
    }
    
    func calls() -> [Call] {
        callList
    }
    
    func calls(user: User) -> [Call] {
        var userCalls: [Call] = []
        for call in callList {
            if call.outgoingUser.id == user.id || call.incomingUser.id == user.id {
                userCalls.append(call)
            }
        }
        return userCalls
    }
    
    func call(id: CallID) -> Call? {
        for call in callList {
            if call.id == id {
                return call
            }
        }
        return nil
    }
    
    func currentCall(user: User) -> Call? {
        for call in callList {
            if ((call.incomingUser.id == user.id || call.outgoingUser.id == user.id) && call.status == .calling) {
                return call
            }
        }
        return nil
    }
    
}
