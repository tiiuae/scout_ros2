# Use the official ROS 2 Iron desktop image as the base
FROM osrf/ros:humble-desktop

# # Specify the base image and ROS distribution
# ARG base_image="ros"
# ARG ros_distro="humble-ros-base"
# FROM ${base_image}:${ros_distro}

# Define user-related arguments
ARG USER_NAME=ros2
ARG USER_UID=1000
ARG USER_HOME=/home/${USER_NAME}
ARG USER_SHELL=/bin/bash
ARG USER_WORKSPACE=${USER_HOME}/ros2_ws

# Set environment variables
ENV DISPLAY=:0
ENV QT_X11_NO_MITSHM=1
ENV USER_WORKSPACE=${USER_WORKSPACE}

# To prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

ENV TZ=ETC/UTC
ENV DEBIAN_FRONTEND=noniteractive
ENV NVIDIA_DRIVER_CAPABILITIES=all

# Create a non-root user
RUN useradd -m -d ${USER_HOME} -s ${USER_SHELL} -u ${USER_UID} ${USER_NAME}

# Switch to root user for system-level installations
USER root

# # Install Gazebo and necessary dependencies
# RUN apt-get update && apt-get install -y \
#     build-essential \
#     gazebo \
#     ros-humble-gazebo-ros-pkgs \
#     ros-humble-gazebo-ros2-control \
#     cmake \
#     ros-humble-xacro \
#     python3-colcon-common-extensions \
#     && rm -rf /var/lib/apt/lists/*

# Update package lists and install additional dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
	lsb-release \
	wget \
	gnupg

RUN wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add -

RUN sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    python3-colcon-common-extensions \
	libqt5svg5 \
	gz-harmonic \
    ros-humble-xacro \
    ros-humble-ros-gz-sim \
    ros-humble-ros2-control \
    ros-humble-ros2-controllers \
    ros-humble-ign-ros2-control \
    ros-humble-ros-gz-bridge \
	&& rm -rf /var/lib/apt/lists/*

# Copy source code into the container
COPY --chown=${USER_NAME}:${USER_NAME} \
./scout_description/launch \
${USER_WORKSPACE}/src/scout_description/launch/

COPY --chown=${USER_NAME}:${USER_NAME} \
./scout_description/meshes \
${USER_WORKSPACE}/src/scout_description/meshes/

COPY --chown=${USER_NAME}:${USER_NAME} \
./scout_description/urdf \
${USER_WORKSPACE}/src/scout_description/urdf/

COPY --chown=${USER_NAME}:${USER_NAME} \
./scout_description/worlds \
${USER_WORKSPACE}/src/scout_description/worlds/

COPY --chown=${USER_NAME}:${USER_NAME} \
./scout_description/CMakeLists.txt \
./scout_description/package.xml \
${USER_WORKSPACE}/src/scout_description/

COPY --chown=${USER_NAME}:${USER_NAME} \
./scout_sim/launch \
${USER_WORKSPACE}/src/scout_sim/launch/

COPY --chown=${USER_NAME}:${USER_NAME} \
./scout_sim/worlds \
${USER_WORKSPACE}/src/scout_sim/worlds/

COPY --chown=${USER_NAME}:${USER_NAME} \
./scout_sim/models \
${USER_WORKSPACE}/src/scout_sim/models/

COPY --chown=${USER_NAME}:${USER_NAME} \
./scout_sim/config \
${USER_WORKSPACE}/src/scout_sim/config/

COPY --chown=${USER_NAME}:${USER_NAME} \
./scout_sim/CMakeLists.txt \
./scout_sim/package.xml \
${USER_WORKSPACE}/src/scout_sim/

# Update user's .bashrc and install ROS dependencies
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc && \
    rosdep update && \
    apt-get update && \
    rosdep install --from-paths ${USER_WORKSPACE}/src --ignore-src -r -y

# Build the ROS workspace
RUN /bin/bash -c '. /opt/ros/humble/setup.bash; cd ${USER_WORKSPACE}; colcon build --symlink-install'

# ENV GAZEBO_MODEL_PATH="$USER_WORKSPACE/src/scout_sim/worlds/small_house/models"
ENV IGN_GAZEBO_RESOURCE_PATH=${USER_WORKSPACE}/src/scout_sim/models

# Switch back to the non-root user
USER ${USER_NAME}

# Set up an entrypoint to source ROS 2 automatically
ENTRYPOINT ["/bin/bash", "-c", "source $USER_WORKSPACE/install/setup.bash && ros2 launch scout_sim robot_spawn.launch.py"]
