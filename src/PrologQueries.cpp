#include "ros/ros.h"
#include <rapidjson/document.h>
#include <rapidjson/stringbuffer.h>
#include <rapidjson/writer.h>

#include "robosherlock_msgs/RSQueryService.h"

#include <ros/package.h>

#include <SWI-cpp.h>

#include <stdio.h>
#include <dlfcn.h>
#include <iostream>
#include <string>
#include <memory>

std::string *req_desig = NULL;


/***************************************************************************
 *                                  ADD DESIGNATOR
 * *************************************************************************/


//what ever happens to all these pointers? This smells like a huge memory leak

PREDICATE(cpp_make_designator, 2)
{
  std::string *desig = new std::string((char *) A1);

  std::cout << "Sending back: " << *desig <<std::endl;
  return A2 = static_cast<void *>(desig);
}


PREDICATE(cpp_query_rs, 1)
{
  void *query = A1;
  std::string *queryString = (std::string *)(query);
  ros::NodeHandle n;
  ros::ServiceClient client = n.serviceClient<robosherlock_msgs::RSQueryService>("RoboSherlock/query");
  robosherlock_msgs::RSQueryService srv;
  std::cout << queryString->c_str() << std::endl;
  srv.request.query = queryString->c_str();
  if (client.call(srv))
  {
    std::cout << "Call was successful" <<std::endl;
    return TRUE;
  }
  else
  {
    std::cout << "Call was unsuccessful"<<std::endl;
    return FALSE;
  }
}


PREDICATE(cpp_add_designator, 2)
{

  std::string desigType((char *)A1);
  std::cout << "Desigtype: " << desigType <<std::endl;

  std::string *desig = new std::string("{\"detect\":{}}");

  std::cout << "Sending back: " << *desig << std::endl;
  return A2 = static_cast<void *>(desig);
}

PREDICATE(cpp_init_kvp, 3)
{
  void *obj = A1;
  std::string type((char *)A2);
  std::cout <<"Type: " << type <<std::endl;
  std::string *desig = (std::string *)(obj);
  std::cout << "Type: " << *desig <<std::endl;
  return A3 = static_cast<void *>(desig);
}

PREDICATE(cpp_add_kvp, 3)
{
  std::string key = (std::string)A1;
  std::string value = (std::string)A2;
  void *obj = A3;
  std::string *desig = (std::string *)(obj);
  std::cout  << "Desig now: " << *desig <<std::endl;
  if(desig)
  {
    std::cout << "Adding Kvp: (" << key << " : " << value << std::endl;
    rapidjson::Document json;
    json.Parse(desig->c_str());
    rapidjson::Value &detectJson = json["detect"];
    rapidjson::Value v(key, json.GetAllocator());
    detectJson.AddMember(v, value, json.GetAllocator());

    rapidjson::StringBuffer buffer;
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
    json.Accept(writer);
    std::string jsonString = buffer.GetString();
    *desig = jsonString;
    return TRUE;
  }
  else
  {
    return FALSE;
  }
}

PREDICATE(cpp_print_desig, 1)
{
  void *obj = A1;
  std::string *desig = (std::string *)(obj);
  if(desig)
  {
    std::cout << *desig << std::endl;
    return TRUE;
  }
  else
  {
    std::cerr << "Desigantor object not initialized. Can not print" << std::endl;
    return FALSE;
  }
}

PREDICATE(cpp_init_desig, 1)
{
  if(!req_desig)
  {
    std::cerr << "Initializing designator: " << std::endl;
    req_desig =  new std::string("{\"location\":{\"location\":\"on table\"}}");
    return A1 = (void *)req_desig;
  }
  else
  {
    std::cerr << "Designator already initialized" << std::endl;
    return FALSE;
  }
}

PREDICATE(cpp_delete_desig, 1)
{
  void *obj = A1;
  std::string *desig = (std::string *)obj;
  delete desig;
  return TRUE;
}


PREDICATE(delete_desig, 1)
{
  if(req_desig)
  {
    delete req_desig;
    req_desig = NULL;
    return TRUE;
  }
  else
  {
    return FALSE;
  }
}


PREDICATE(write_list, 1)
{
  PlTail tail(A1);
  PlTerm e;

  while(tail.next(e))
  {
    std::cout << (char *)e << std::endl;
  }
  return TRUE;
}
