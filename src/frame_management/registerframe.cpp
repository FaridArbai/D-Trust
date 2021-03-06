#include "registerframe.h"
#include <src/frame_management/mainframe.h>

const string RegisterFrame::DEFAULT_STATUS = "This app is hilarious! :D";
const string RegisterFrame::DEFAULT_IMAGE_NAME = "default.png";

RegisterFrame::RegisterFrame(QObject *parent) : QObject(parent) {
}

RegisterFrame::RegisterFrame(RequestHandler* request_handler):RequestingFrame(request_handler){
}

void RegisterFrame::signUp(QString entered_username, QString entered_password){
    MainFrame::showProgressDialog("Registering new user");
    QFuture<void> future = QtConcurrent::run(this, &RegisterFrame::signUpImpl,
                                             entered_username.toStdString(), entered_password.toStdString());
}

void RegisterFrame::signUpImpl(string username, string password){
    PM_regReq request_pm(username,password);
    ProtocolMessage* response_pm;
    bool result;
    string feedback_message;

    response_pm = this->request_handler->recvResponseFor(&request_pm);
    result = ((PM_regRep*)response_pm)->getResult();

    if(result==true){
        MainFrame::showProgressDialog("Saving data");
        feedback_message = "User " + username + " registered";
        QFuture<void> future = QtConcurrent::run(this, &RegisterFrame::saveDataImpl, username, password);
    }
    else{
        MainFrame::dismissProgressDialog();
        feedback_message = ((PM_regRep*)response_pm)->getErrMsg();
    }

    delete response_pm;
    emit receivedRegisterResponse(QString::fromStdString(feedback_message),result);
}

void RegisterFrame::saveDataImpl(string username, string password){
    PrivateUser* user = this->createDefaultUser(username,password);
    IOManager::saveUser(user);
    delete user;
    MainFrame::dismissProgressDialog();
}

PrivateUser* RegisterFrame::createDefaultUser(string username, string password){
    string default_status = RegisterFrame::DEFAULT_STATUS;
    string path_to_default_image = IOManager::getImagePath(RegisterFrame::DEFAULT_IMAGE_NAME);

    PrivateUser* default_user =
            new PrivateUser(username,
                            default_status,
                            path_to_default_image);

    this->sendDefaultParams(username,password);

    return default_user;
}

void RegisterFrame::sendDefaultParams(string username, string password){
    PM_logReq log_req(username,password);
    PM_logOutReq log_out_req = PM_logOutReq();
    ProtocolMessage* pm_response;
    bool logged_in;

    pm_response = this->request_handler->recvResponseFor(&log_req);

    logged_in = ((PM_logRep*)pm_response)->getResult();

    delete pm_response;

    if(logged_in){
        PM_updateStatus update_status(username,
                                      PM_updateStatus::StatusType::status,
                                      RegisterFrame::DEFAULT_STATUS);
        this->request_handler->sendTrap(&update_status);

        string path_to_default_image =
                IOManager::getImagePath(RegisterFrame::DEFAULT_IMAGE_NAME);
        Avatar avatar(path_to_default_image);
        PM_updateStatus update_image(username,avatar);
        this->request_handler->sendTrap(&update_image);

        pm_response = this->request_handler->recvResponseFor(&log_out_req);

        delete pm_response;
    }
}




























