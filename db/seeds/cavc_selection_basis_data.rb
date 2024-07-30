# frozen_string_literal: true

# Cavc Selection Basis seeds
module Seeds
  class CavcSelectionBasisData < Base
    def seed!
      create_cavc_selection_basis
    end

    private

    def create_cavc_selection_basis

      other_due_process_protection = [
        "Pending Privacy Act Request", "AMA Opt-in", "Extension request", "20.104(c)",
        "20.1304(c)", "20.604", "20.712(c)", "AMA Opt-In Post SSOC", "Credibility Finding in Prior Remand",
        "Send Docketing Letter", "Failure to Explain Findings", "Failure to Hold Record Open",
        "Failure to Honor Stay", "No jurisdiction", "Provide Notice and Opportunity to Respond",
        "AOJ Adjudication Needed", "Refer for Extraschedular Consideration", "Other"
      ]

      prior_examination_inadequate = [
        "Lay Statements Not Considered", "VA Medical Records Not Considered","Private Treament Records Not Considered",
        "Service Records Not Considered", "Johnson (2018)", "Correia", "Ray", "Clemons", "Sharp", "Chavis", "Miller", "English",
        "Francway", "Rice", "Lyles", "Robinson", "Swain", "Chotta", "McLendon", "Barr", "Reonal", "Bailey", "Mitchell", "Bankhead",
        "Jones (2012)", "Quinn", "Buchanan", "Deluca", "El-Amin", "Saunders", "Floore", "Nieves-Rodriguez", "Smith", "Withers", "Stefl",
        "Delrio", "Fountain", "DeLisio", "Mauerhan", "Monzingo", "Tucker", "Caluza", "Buie", "Bradley", "Thun", "Harper", "Tatum", "Hart",
        "Walsh","Buczynski","Wise","Cook","Hensley","Snider","Stegall","Overton","Atencio","Stewart","DelaCruz","AB","Dalton","Wagner","McGrath",
        "Garner","King","Pierce","Cullen","Cantrell","Bryant","O'Hare","McCray","Vazquez-Claudio","Allday","Geib","Kahana","Burton","Stankevich",
        "Smiddy","Horn","Svehla","Jandreau","Schafrath","Combee","Esteban","McKinney","Euzebio","Washington","Frost","Pernorio","Ward","Dennis",
        "Ortiz-Valles","Wages","Ardison","Dofflemyer","McClain","Savage","Gutierrez","Walker","McNair","Roberson","Caffrey","Russo","Hall","Shade",
        "Bardwell","Long","Polovick","Comer","McCarroll","Healey","Gleicher","Palczewski","Beraud","Boggs","Brokowski","Brown","Sprinkle","Molitor",
        "Buckley","Reeves","Golden","Daves","Gilbert","Moore","Southall-Norman","Cosman","Jarrell","Lang","Arline","Delisle","Bond","Percy","Henderson",
        "Medrano","McDowell","Ephraim","Gazelle","Beaty","Acree","Fagan","KisorIII","Gaston","Alpough","Blubaugh","Ortiz","Fenderson","Kuzma","Friscia",
        "Helmick","Colvin","Langdon","Golz","Payne","Eubzebio","Layno","Suttman","Acevedo","Tedesco","Allen","Akles","Manlicon","Cogburn","Pratt","Nehmer",
        "Manlincon","Espiritu","Quirin","Snuffer","Martin","Sowers","Hickson","Joyner","McCarrol","Mittleider","Dyment","Sullivan","Holmes","Mittlleider",
        "Harris","Justus","Romero","Thompson","Todd","Beyrle","Vaquez-Claudio","Hudgens","Disabled Am. Veterans","Biestek","Morgan","Geibce","Khana",
        "McLain","Waters","Sizemore","Hatlestad","Murray","Myers","Karnas","Other",
      ]

      prior_opinion_inadequate = [
        "Lay Statements Not Considered","VA Medical Records Not Considered","Private Treament Records Not Considered",
        "Service Records Not Considered","Aggravation Opinion Not Provided","Secondary Causation Opinion Not Provided",
        "Inconsistent/Contradictory Findings","Other Medical Evdience Not Considered","Inadequate Rationale","Correia",
        "Reonal","Johnson (2018)","Ray","Sharp","Chavis","Miller","English","Bailey","Clemons","Lyles","Francway","Rice",
        "Chotta","McLendon","Barr","Robinson","Swain","Mitchell","Bankhead","Jones (2012)","Quinn","Buchanan","Deluca","El-Amin",
        "Saunders","Floore","Nieves-Rodriguez","Smith","Withers","Stefl","Delrio","Fountain","DeLisio","Mauerhan","Monzingo",
        "Tucker","Caluza","Buie","Bradley","Thun","Harper","Tatum","Hart","Walsh","Buczynski","Wise","Cook","Hensley","Snider",
        "Stegall","Overton","Atencio","Stewart","DelaCruz","AB","Dalton","Wagner","McGrath","Garner","King","Pierce","Cullen",
        "Cantrell","Bryant","O'Hare","McCray","Vazquez-Claudio","Allday","Geib","Kahana","Burton","Stankevich","Smiddy","Horn",
        "Svehla","Jandreau","Schafrath","Combee","Esteban","McKinney","Euzebio","Washington","Frost","Pernorio","Ward","Dennis",
        "Ortiz-Valles","Wages","Ardison","Dofflemyer","McClain","Savage","Gutierrez","Walker","McNair","Roberson","Caffrey","Russo",
        "Hall","Shade","Bardwell","Long","Polovick","Comer","McCarroll","Healey","Gleicher","Palczewski","Beraud","Boggs","Brokowski",
        "Brown","Sprinkle","Molitor","Buckley","Reeves","Golden","Daves","Gilbert","Moore","Southall-Norman","Cosman","Jarrell","Lang",
        "Arline","Delisle","Bond","Percy","Henderson","Medrano","McDowell","Ephraim","Gazelle","Beaty","Acree","Fagan","KisorIII","Gaston",
        "Alpough","Blubaugh","Ortiz","Fenderson","Kuzma","Friscia","Helmick","Colvin","Langdon","Golz","Payne","Eubzebio","Layno","Suttman",
        "Acevedo","Tedesco","Allen","Akles","Manlicon","Cogburn","Pratt","Nehmer","Manlincon","Espiritu","Quirin","Snuffer","Martin","Sowers",
        "Hickson","Joyner","McCarrol","Mittleider","Dyment","Sullivan","Holmes","Mittlleider","Harris","Justus","Romero","Thompson","Todd",
        "Beyrle","Vaquez-Claudio","Hudgens","Disabled Am. Veterans","Biestek","Morgan","Geibce","Khana","McLain","Waters","Sizemore",
        "Hatlestad","Murray","Myers","Karnas","Other"
      ]

      statute = [
        "1111","1114","1117","1153","1154","7104","7107",
        "7305","1114(l)","1114(r)(2)","1114(s)","1116B",
        "1154(b)","5103A(c)(2)","5103A(d)(1)","5107(b)",
        "5110(b)(3)","7105(d)(1)","Other"
      ]

      regulation = [
        "1.577","3.03","3.114","3.156","3.159","3.303","3.309",
        "3.311","3.312","3.317","3.32","3.4","4.114","4.118",
        "4.123","4.124","4.13","4.18","4.2","4.4","4.45","4.59",
        "4.3","4.56","19.29","19.36","19.37","20.104","20.12",
        "20.703","19.27(b)","20.1305(a)","20.1305(c)","21.53(e)(2)",
        "4.40","3.114(a)","3.156(a)","3.156(b)","3.156(c)","3.156(c)(1)",
        "3.159(c)","3.159(c)(2)","3.159(c)(3)","3.159(e)","3.159(e)(1)",
        "3.159(e)(2)","3.203(c)","3.2400(c)(2)","3.30(b)","3.303(b)","3.303(c)",
        "3.304(b)","3.306(a)","3.309(a)","3.317(a)(2)(i)","3.317(a)(2)(ii)",
        "3.317(a)(3)","3.321(b)","3.321(b)(1)","3.340(a)","3.350(i)","3.350(i)(1)",
        "3.352(a)","3.361(d)(2)","3.400(o)","3.400(o)(2)","3.816(f)","3.951(b)","4.115A",
        "4.124a","4.156(b)","4.16(a)","4.16(a)(2)","4.16(a)(3)","4.16(b)","4.2","4.45(f)",
        "4.71a","4.86(a)","4.88a","Other"
      ]

      diagnostic_code = [
        "5000", "5001", "5002", "5003", "5004", "5005", "5006", "5007", "5008", "5009", "5010", "5011", "5012", "5013", "5014", "5015",
        "5016", "5017", "5018", "5020", "5021", "5023", "5019", "5022", "5024", "5025", "5051", "5052", "5053", "5054", "5055", "5056",
        "5099", "5100", "5101", "5102", "5103", "5104", "5105", "5106", "5107", "5108", "5109", "5110", "5111", "5120", "5121", "5122",
        "5123", "5124", "5125", "5126", "5127", "5128", "5129", "5130", "5131", "5132", "5133", "5134", "5135", "5136", "5137", "5138",
        "5139", "5140", "5141", "5142", "5143", "5144", "5145", "5146", "5147", "5148", "5149", "5150", "5151", "5152", "5153", "5154",
        "5155", "5156", "5160", "5161", "5162", "5163", "5164", "5165", "5166", "5167", "5170", "5171", "5172", "5173", "5174", "5199",
        "5200", "5201", "5202", "5203", "5205", "5206", "5207", "5208", "5209", "5210", "5211", "5212", "5213", "5214", "5215", "5216",
        "5217", "5218", "5219", "5220", "5221", "5222", "5223", "5224", "5225", "5226", "5227", "5228", "5229", "5230", "5235", "5236",
        "5237", "5238", "5239", "5240", "5241", "5242", "5243", "5250", "5251", "5252", "5253", "5254", "5255", "5256", "5257", "5258",
        "5259", "5260", "5261", "5262", "5263", "5264", "5270", "5271", "5272", "5273", "5274", "5275", "5276", "5277", "5278", "5279",
        "5280", "5281", "5282", "5283", "5284", "5285", "5286", "5287", "5288", "5289", "5290", "5291", "5292", "5293", "5294", "5295",
        "5296", "5297", "5298", "5299", "5301", "5302", "5303", "5304", "5305", "5306", "5307", "5308", "5309", "5310", "5311", "5312",
        "5313", "5314", "5315", "5316", "5317", "5318", "5319", "5320", "5321", "5322", "5323", "5324", "5325", "5326", "5327", "5328",
        "5329", "5399", "6000", "6001", "6002", "6003", "6004", "6005", "6006", "6007", "6008", "6009", "6010", "6011", "6012", "6013",
        "6014", "6015", "6016", "6017", "6018", "6019", "6020", "6021", "6022", "6023", "6024", "6025", "6026", "6027", "6028", "6029",
        "6030", "6031", "6032", "6033", "6034", "6035", "6036", "6037", "6040", "6042", "6046", "6050", "6051", "6052", "6053", "6054",
        "6055", "6056", "6057", "6058", "6059", "6060", "6061", "6062", "6063", "6064", "6065", "6066", "6067", "6068", "6069", "6070",
        "6071", "6072", "6073", "6074", "6075", "6076", "6077", "6078", "6079", "6080", "6081", "6090", "6091", "6092", "6099", "6100",
        "6101", "6102", "6103", "6104", "6105", "6106", "6107", "6108", "6109", "6110", "6199", "6200", "6201", "6202", "6203", "6204",
        "6205", "6206", "6207", "6208", "6209", "6210", "6211", "6250", "6251", "6252", "6253", "6254", "6255", "6256", "6257", "6258",
        "6260", "6261", "6262", "6263", "6275", "6276", "6277", "6278", "6279", "6280", "6281", "6282", "6283", "6284", "6285", "6286",
        "6287", "6288", "6289", "6290", "6291", "6292", "6293", "6294", "6295", "6296", "6297", "6299", "6300", "6301", "6302", "6304",
        "6305", "6306", "6307", "6308", "6309", "6310", "6311", "6312", "6313", "6314", "6315", "6316", "6317", "6318", "6319", "6320",
        "6325", "6326", "6329", "6330", "6331", "6333", "6350", "6351", "6352", "6353", "6354", "6399", "6501", "6502", "6504", "6510",
        "6511", "6512", "6513", "6514", "6515", "6516", "6517", "6518", "6519", "6520", "6521", "6522", "6523", "6524", "6599", "6600",
        "6601", "6602", "6603", "6604", "6699", "6701", "6702", "6703", "6704", "6705", "6706", "6707", "6708", "6709", "6710", "6711",
        "6712", "6713", "6714", "6721", "6722", "6723", "6724", "6725", "6726", "6727", "6728", "6730", "6731", "6732", "6799", "6800",
        "6801", "6802", "6803", "6804", "6805", "6806", "6807", "6808", "6809", "6810", "6811", "6812", "6813", "6814", "6815", "6816",
        "6817", "6818", "6819", "6820", "6821", "6822", "6823", "6824", "6825", "6826", "6827", "6828", "6829", "6830", "6831", "6832",
        "6833", "6834", "6835", "6836", "6837", "6838", "6839", "6840", "6841", "6842", "6843", "6844", "6845", "6846", "6847", "6899",
        "7000", "7001", "7002", "7003", "7004", "7005", "7006", "7007", "7008", "7010", "7011", "7012", "7013", "7014", "7015", "7016",
        "7017", "7018", "7019", "7020", "7099", "7100", "7101", "7110", "7111", "7112", "7113", "7114", "7115", "7116", "7117", "7118",
        "7119", "7120", "7121", "7122", "7123", "7199", "7200", "7201", "7202", "7203", "7204", "7205", "7299", "7301", "7302", "7304",
        "7305", "7306", "7307", "7308", "7309", "7310", "7311", "7312", "7313", "7314", "7315", "7316", "7317", "7318", "7319", "7320",
        "7321", "7322", "7323", "7324", "7325", "7326", "7327", "7328", "7329", "7330", "7331", "7332", "7333", "7334", "7335", "7336",
        "7337", "7338", "7339", "7340", "7341", "7342", "7343", "7344", "7345", "7346", "7347", "7348", "7351", "7354", "7399", "7500",
        "7501", "7502", "7503", "7504", "7505", "7506", "7507", "7508", "7509", "7510", "7511", "7512", "7513", "7514", "7515", "7516",
        "7517", "7518", "7519", "7520", "7521", "7522", "7523", "7524", "7525", "7526", "7527", "7528", "7529", "7530", "7531", "7532",
        "7533", "7534", "7535", "7536", "7537", "7538", "7539", "7540", "7541", "7542", "7599", "7610", "7611", "7612", "7613", "7614",
        "7615", "7617", "7618", "7619", "7620", "7621", "7622", "7623", "7624", "7625", "7626", "7627", "7628", "7629", "7630", "7631",
        "7632", "7699", "7700", "7701", "7702", "7703", "7704", "7705", "7706", "7707", "7709", "7710", "7711", "7712", "7713", "7714",
        "7715", "7716", "7717", "7718", "7719", "7720", "7721", "7722", "7723", "7724", "7725", "7799", "7800", "7801", "7802", "7803",
        "7804", "7805", "7806", "7807", "7808", "7809", "7810", "7811", "7812", "7813", "7814", "7815", "7816", "7817", "7818", "7819",
        "7820", "7821", "7822", "7823", "7824", "7825", "7826", "7827", "7828", "7829", "7830", "7831", "7832", "7833", "7899", "7900",
        "7901", "7902", "7903", "7904", "7905", "7906", "7907", "7908", "7909", "7910", "7911", "7912", "7913", "7914", "7915", "7916",
        "7917", "7918", "7919", "7999", "8000", "8001", "8002", "8003", "8004", "8005", "8007", "8008", "8009", "8010", "8011", "8012",
        "8013", "8014", "8015", "8017", "8018", "8019", "8020", "8021", "8022", "8023", "8024", "8025", "8026", "8045", "8046", "8099",
        "8100", "8103", "8104", "8105", "8106", "8107", "8108", "8199", "8205", "8207", "8209", "8210", "8211", "8212", "8299", "8305",
        "8307", "8309", "8310", "8311", "8312", "8399", "8405", "8407", "8409", "8410", "8411", "8412", "8499", "8510", "8511", "8512",
        "8513", "8514", "8515", "8516", "8517", "8518", "8519", "8520", "8521", "8522", "8523", "8524", "8525", "8526", "8527", "8528",
        "8529", "8530", "8540", "8599", "8610", "8611", "8612", "8613", "8614", "8615", "8616", "8617", "8618", "8619", "8620", "8621",
        "8622", "8623", "8624", "8625", "8626", "8627", "8628", "8629", "8630", "8699", "8710", "8711", "8712", "8713", "8714", "8715",
        "8716", "8717", "8718", "8719", "8720", "8721", "8722", "8723", "8724", "8725", "8726", "8727", "8728", "8729", "8730", "8799",
        "8850", "8851", "8852", "8853", "8860", "8861", "8862", "8863", "8865", "8866", "8867", "8868", "8870", "8871", "8872", "8873",
        "8875", "8876", "8877", "8878", "8879", "8880", "8881", "8882", "8883", "8884", "8885", "8886", "8887", "8889", "8892", "8893",
        "8894", "8895", "8899", "8900", "8901", "8902", "8910", "8911", "8912", "8913", "8914", "8999", "9000", "9001", "9002", "9003",
        "9004", "9005", "9006", "9007", "9008", "9009", "9010", "9011", "9012", "9013", "9014", "9015", "9016", "9017", "9018", "9019",
        "9020", "9021", "9022", "9023", "9024", "9025", "9026", "9027", "9028", "9029", "9030", "9031", "9032", "9033", "9034", "9035",
        "9036", "9037", "9038", "9039", "9040", "9041", "9042", "9043", "9044", "9045", "9046", "9047", "9048", "9049", "9050", "9051",
        "9052", "9053", "9054", "9055", "9099", "9100", "9101", "9102", "9103", "9104", "9105", "9106", "9110", "9111", "9112", "9199",
        "9200", "9201", "9202", "9203", "9204", "9205", "9206", "9207", "9208", "9209", "9210", "9211", "9299", "9300", "9301", "9302",
        "9303", "9304", "9305", "9306", "9307", "9308", "9309", "9310", "9311", "9312", "9313", "9314", "9315", "9316", "9317", "9318",
        "9319", "9320", "9321", "9322", "9323", "9324", "9325", "9326", "9327", "9399", "9400", "9401", "9402", "9403", "9404", "9405",
        "9406", "9407", "9408", "9409", "9410", "9411", "9412", "9413", "9416", "9417", "9421", "9422", "9423", "9424", "9425", "9431",
        "9432", "9433", "9434", "9435", "9440", "9499", "9500", "9501", "9502", "9503", "9504", "9505", "9506", "9507", "9508", "9509",
        "9510", "9511", "9520", "9521", "9599", "9900", "9901", "9902", "9903", "9904", "9905", "9906", "9907", "9908", "9909", "9910",
        "9911", "9912", "9913", "9914", "9915", "9916", "9917", "9918", "9999", "Other"
      ]

      caselaw = [
        "Correia", "Sharp", "Johnson (2018)", "Ray", "Miller", "Chavis", "English", "Mitchell",
        "Francway", "Rice", "Chotta", "McLendon", "Barr", "Reonal", "Bankhead", "Jones (2012)",
        "Quinn", "Bailey", "Clemons", "Lyles", "Robinson", "Swain", "Buchanan", "Deluca", "El-Amin",
        "Saunders", "Floore", "Nieves-Rodriguez", "Smith", "Withers", "Stefl", "Delrio", "Fountain",
        "DeLisio", "Mauerhan", "Monzingo", "Tucker", "Caluza", "Buie", "Bradley", "Thun", "Harper",
        "Tatum", "Hart", "Walsh", "Buczynski", "Wise", "Cook", "Hensley", "Snider", "Stegall", "Overton",
        "Atencio", "Stewart", "DelaCruz", "AB", "Dalton", "Wagner", "McGrath", "Garner", "King", "Pierce",
        "Cullen", "Cantrell", "Bryant", "O'Hare", "McCray", "Vazquez-Claudio", "Allday", "Geib", "Kahana",
        "Burton", "Stankevich", "Smiddy", "Horn", "Svehla", "Jandreau", "Schafrath", "Combee", "Esteban",
        "McKinney", "Euzebio", "Washington", "Frost", "Pernorio", "Ward", "Dennis", "Ortiz-Valles", "Wages",
        "Ardison", "Dofflemyer", "McClain", "Savage", "Gutierrez", "Walker", "McNair", "Roberson", "Caffrey",
        "Russo", "Hall", "Shade", "Bardwell", "Long", "Polovick", "Comer", "McCarroll", "Healey", "Gleicher",
        "Palczewski", "Beraud", "Boggs", "Brokowski", "Brown", "Sprinkle", "Molitor", "Buckley", "Reeves",
        "Golden", "Daves", "Gilbert", "Moore", "Southall-Norman", "Cosman", "Jarrell", "Lang", "Arline",
        "Delisle", "Bond", "Percy", "Henderson", "Medrano", "McDowell", "Ephraim", "Gazelle", "Beaty", "Acree",
        "Fagan", "KisorIII", "Gaston", "Alpough", "Blubaugh", "Ortiz", "Fenderson", "Kuzma", "Friscia", "Helmick",
        "Colvin", "Langdon", "Golz", "Payne", "Eubzebio", "Layno", "Suttman", "Acevedo", "Tedesco", "Allen", "Akles",
        "Manlicon", "Cogburn", "Pratt", "Nehmer", "Manlincon", "Espiritu", "Quirin", "Snuffer", "Martin", "Sowers",
        "Hickson", "Joyner", "McCarrol", "Mittleider", "Dyment", "Sullivan", "Holmes", "Mittlleider", "Harris",
        "Justus", "Romero", "Thompson", "Todd", "Beyrle", "Vaquez-Claudio", "Hudgens", "Disabled Am. Veterans",
        "Biestek", "Morgan", "Geibce", "Khana", "McLain", "Waters", "Sizemore", "Hatlestad", "Murray", "Myers",
        "Karnas", "Other"
      ]

      other = ["Other"]

      odpp = other_due_process_protection.map{ |value| {basis_for_selection: value, category: "other_due_process_protection"} }
      CavcSelectionBasis.import(odpp, validate: false)

      pei = prior_examination_inadequate.map{ |value| {basis_for_selection: value, category: "prior_examination_inadequate"} }
      CavcSelectionBasis.import(pei, validate: false)

      poi = prior_opinion_inadequate.map { |value| {basis_for_selection: value, category: "prior_opinion_inadequate"} }
      CavcSelectionBasis.import(poi, validate: false)

      consider_statue = statute.map { |value| { basis_for_selection: value, category: "consider_statute" } }
      CavcSelectionBasis.import(consider_statue, validate: false)

      misapplication_statute = statute.map { |value| { basis_for_selection: value, category: "misapplication_statute" } }
      CavcSelectionBasis.import(misapplication_statute, validate: false)

      consider_regulation = regulation.map { |value| { basis_for_selection: value, category: "consider_regulation" } }
      CavcSelectionBasis.import(consider_regulation, validate: false)

      misapplication_regulation = regulation.map { |value| { basis_for_selection: value, category: "misapplication_regulation" } }
      CavcSelectionBasis.import(misapplication_regulation, validate: false)

      consider_diagnostic_code = diagnostic_code.map { |value| { basis_for_selection: value, category: "consider_diagnostic_code" } }
      CavcSelectionBasis.import(consider_diagnostic_code, validate: false)

      misapplication_diagnostic_code = diagnostic_code.map { |value| { basis_for_selection: value, category: "misapplication_diagnostic_code" } }
      CavcSelectionBasis.import(misapplication_diagnostic_code, validate: false)

      consider_caselaw = caselaw.map { |value| { basis_for_selection: value, category: "consider_caselaw" } }
      CavcSelectionBasis.import(consider_caselaw, validate: false)

      misapplication_caselaw = caselaw.map { |value| { basis_for_selection: value, category: "misapplication_caselaw" } }
      CavcSelectionBasis.import(misapplication_caselaw, validate: false)

      ama_other = other.map { |value| { basis_for_selection: value, category: "ama_other" } }
      CavcSelectionBasis.import(ama_other, validate: false)
    end
  end
end
