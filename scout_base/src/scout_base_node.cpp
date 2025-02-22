/*
 * scout_base_node.cpp
 *
 * Created on: Oct 15, 2021 16:20
 * Description:
 *
 * Copyright (c) 2021 Weston Robot Pte. Ltd.
 */

#include <memory>

#include <rclcpp/rclcpp.hpp>
#include <rclcpp/executor.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <sensor_msgs/msg/joint_state.hpp>
#include <tf2_ros/transform_broadcaster.h>

#include "scout_base/scout_base_ros.hpp"

using namespace westonrobot;

void DetachRobot(int signal, std::shared_ptr<ScoutBaseRos> robot) {
    (void)signal;
    if (robot) {
        robot->Stop();
    }
}

int main(int argc, char **argv) {
  // setup ROS node
  rclcpp::init(argc, argv);
  //   std::signal(SIGINT, DetachRobot);

  std::shared_ptr<ScoutBaseRos> robot;

  robot = std::make_shared<ScoutBaseRos>("scout");

  if (robot->Initialize()) {
    std::cout << "Robot initialized, start running ..." << std::endl;
    robot->Run();
  }
  else {
    std::cout << "Failed to initialize the robot, shutting down..." << std::endl;
  }

  rclcpp::shutdown();

  return 0;
}