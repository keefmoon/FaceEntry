//
//  FaceManager.swift
//  FaceEntry
//
//  Created by Keith Moon on 01/04/2017.
//  Copyright © 2017 Keith Moon. All rights reserved.
//

import Foundation

enum Result<ResultType> {
    case success(ResultType)
    case failure(Error)
}

struct PersonGroup {
    let personGroupID: String
}

struct Person {
    let personID: String
}

struct Face {
    let faceID: String
}

struct CandidatePerson {
    let person: Person
    let confidence: Float
}

class FaceManager {
    
    private enum Key: String {
        case authorisedPersonGroupID
        case defaultPersonID
    }
    
    enum Error: Swift.Error {
        case unexpectedResponse
    }
    
    let faceServiceClient = MPOFaceServiceClient(subscriptionKey: subscriptionKey)!
    let userDefaults = UserDefaults.standard
    
    // MARK: Creation / Retrieval
    
    func getAuthorisedFaceGroup(completionHandler: @escaping (Result<PersonGroup>) -> Void) {
        
        if let authorisedPersonGroupID = userDefaults.string(forKey: Key.authorisedPersonGroupID.rawValue) {
            
            let faceGroup = PersonGroup(personGroupID: authorisedPersonGroupID)
            completionHandler(.success(faceGroup))
        
        } else {
            
            let personGroupID = UUID().uuidString.lowercased()
            let personGroupName = "AuthorisedPeople2"
            
            faceServiceClient.createPersonGroup(withId: personGroupID,
                                                name: personGroupName,
                                                userData: nil) { [userDefaults] error in
                                                    
                                                    switch error {
                                                        
                                                    case .some(let error):
                                                        completionHandler(.failure(error))
                                                        
                                                    case .none:
                                                        userDefaults.set(personGroupID, forKey: Key.authorisedPersonGroupID.rawValue)
                                                        userDefaults.synchronize()
                                                        let personGroup = PersonGroup(personGroupID: personGroupID)
                                                        completionHandler(.success(personGroup))
                                                    }
            }
        }
    }
    
    func getDefaultPerson(in group: PersonGroup, completionHandler: @escaping (Result<Person>) -> Void) {
     
        let personKey = "\(group.personGroupID) | \(Key.defaultPersonID.rawValue)"
        
        if let defaultPersonID = userDefaults.string(forKey: personKey) {
        
            let person = Person(personID: defaultPersonID)
            completionHandler(.success(person))
            
        } else {
            
            let personName = "Default"
            faceServiceClient.createPerson(withPersonGroupId: group.personGroupID,
                                           name: personName,
                                           userData: nil) { [userDefaults] (result, error) in
                                            
                                            if let error = error {
                                                
                                                completionHandler(.failure(error))
                                                
                                            } else if let result = result, let personID = result.personId {
                                                
                                                userDefaults.set(personID, forKey: personKey)
                                                userDefaults.synchronize()
                                                let person = Person(personID: personID)
                                                completionHandler(.success(person))
                                            }
            }
        }
    }
    
    // MARK: Identify
    
    func identify(imageData: Data, in group: PersonGroup, completionHandler: @escaping (Result<[CandidatePerson]>) -> Void) {
        
        getFaceID(forImageData: imageData) { [weak self] result in
            
            switch result {
            case .success(let face): self?.identify(face, in: group, completionHandler: completionHandler)
            case .failure(let error): completionHandler(.failure(error))
            }
        }
    }
    
    private func getFaceID(forImageData imageData: Data, completionHandler: @escaping (Result<Face>) -> Void) {
        
        faceServiceClient.detect(with: imageData,
                                 returnFaceId: true,
                                 returnFaceLandmarks: true,
                                 returnFaceAttributes: []) { (faces, error) in
                                    
                                    switch (faces, error) {
                                        
                                    case (let faces?, nil):
                                        guard let firstFace = faces.first else {
                                            completionHandler(.failure(Error.unexpectedResponse))
                                            return
                                        }
                                        let face = Face(faceID: firstFace.faceId)
                                        completionHandler(.success(face))
                                        
                                    case (nil, let error?):
                                        completionHandler(.failure(error))
                                        
                                    default:
                                        completionHandler(.failure(Error.unexpectedResponse))
                                    }
        }
    }
    
    private func identify(_ face: Face, in group: PersonGroup, completionHandler: @escaping (Result<[CandidatePerson]>) -> Void) {
        
        faceServiceClient.identify(withPersonGroupId: group.personGroupID, faceIds: [face.faceID], maxNumberOfCandidates: 1) { (result, error) in
            
            switch (result, error) {
                
            case (let result?, nil):
                
                guard let firstResult = result.first, let candidates = firstResult.candidates as? [MPOCandidate] else {
                    completionHandler(.failure(Error.unexpectedResponse))
                    return
                }
                
                let candidatePeople = candidates.map { candidate -> CandidatePerson in
                    let person = Person(personID: candidate.personId)
                    let confidence = candidate.confidence.floatValue
                    return CandidatePerson(person: person, confidence: confidence)
                }
                completionHandler(.success(candidatePeople))
                
            case (_, let error?):
                completionHandler(.failure(error))
                
            default:
                completionHandler(.failure(Error.unexpectedResponse))
            }
        }
    }
    
    // MARK: Train
    
    func addTrainingImageData(_ imageData: Data,
                              for person: Person,
                              in group: PersonGroup,
                              completionHandler: @escaping (Result<Face>) -> Void) {
        
        faceServiceClient.detect(with: imageData,
                                 returnFaceId: true,
                                 returnFaceLandmarks: true,
                                 returnFaceAttributes: []) { [weak self] (faces, error) in
                                    
                                    switch (faces, error) {
                                        
                                    case (let faces?, nil):
                                        guard let firstFace = faces.first else {
                                            completionHandler(.failure(Error.unexpectedResponse))
                                            return
                                        }
                                        self?.addTrainingFace(firstFace, fromImageData: imageData, for: person, in: group, completionHandler: completionHandler)
                                        
                                    case (nil, let error?):
                                        completionHandler(.failure(error))
                                        
                                    default:
                                        completionHandler(.failure(Error.unexpectedResponse))
                                    }
        }
    }
    
    private func addTrainingFace(_ face: MPOFace,
                                 fromImageData imageData: Data,
                                 for person: Person,
                                 in group: PersonGroup,
                                 completionHandler: @escaping (Result<Face>) -> Void) {
        
        faceServiceClient.addPersonFace(withPersonGroupId: group.personGroupID,
                                        personId: person.personID,
                                        data: imageData,
                                        userData: nil,
                                        faceRectangle: face.faceRectangle) { (result, error) in
                                            
                                            switch (result, error) {
                                                
                                            case (let result?, nil):
                                                guard let faceID = result.persistedFaceId else {
                                                    completionHandler(.failure(Error.unexpectedResponse))
                                                    return
                                                }
                                                let resultFace = Face(faceID: faceID)
                                                completionHandler(.success(resultFace))
                                                
                                            case (nil, let error?):
                                                completionHandler(.failure(error))
                                                
                                            default:
                                                completionHandler(.failure(Error.unexpectedResponse))
                                            }
        }
    }
    
    func train(_ group: PersonGroup, completionHandler: @escaping (Result<Void>) -> Void) {
        
        faceServiceClient.trainPersonGroup(withPersonGroupId: group.personGroupID) { error in
            
            switch error {
            case .some(let error): completionHandler(.failure(error))
            case .none: completionHandler(.success())
            }
        }
        
    }
    
}
